// Repopulates course/enrollment/assessment/submission/attendance data with
// realistic variety instead of today's mostly-1:1 relationships (1 lecturer
// : 1 course, 1 student : 1 course, 1 assessment : 1 course). Runs entirely
// through the app's own `admin_role` connection (ALL PRIVILEGES on slms.*),
// so - unlike sql/09_assessment_weights_and_gpa.sql - this does NOT need
// root and can be run directly: `node scripts/repopulate-demo-data.js`.
//
// Keeps the existing STUDENT/Lecturer/Admin_USER/APP_USER rows (S001-S020,
// L001-L020, A001-A020) untouched - same logins keep working - and adds
// more of the same ID scheme (L021-L030, S021-S050) so there's enough
// people to build real variety from. Wipes and regenerates everything from
// COURSE down (COURSE, TIMETABLE, ENROLLMENT, ASSESSMENT, SUBMISSION,
// SUBMISSION_AUDIT_LOG, ATTENDANCE) since those are what need the richer
// shape.
//
// Uses stored procedures where ID-generation/uniqueness logic matters
// (sp_create_student/sp_create_lecturer, sp_enroll_student,
// sp_create_assessment) and direct batched INSERTs for bulk rows
// (TIMETABLE, SUBMISSION, ATTENDANCE) where a procedure would fight
// generating thousands of rows with controlled dates.

require('dotenv').config();
const bcrypt = require('bcrypt');
const { withRole, pool } = require('../src/db');

const BCRYPT_ROUNDS = 10;
const PASSWORD = 'Password123!';

const FIRST_NAMES = [
  'Ama', 'Kwame', 'Adjoa', 'Kojo', 'Akosua', 'Yaw', 'Abena', 'Kwabena', 'Efua', 'NanaYaa',
  'Kwesi', 'Akua', 'Kwaku', 'Afia', 'Kweku', 'Adwoa', 'Kwadwo', 'Araba', 'Nii', 'Naa',
  'Esi', 'Kobby', 'Adoma', 'Yaa', 'Kofi', 'Abla', 'Nana', 'Aba', 'Kodwo', 'Serwaa',
];
const LAST_NAMES = [
  'Owusu', 'Mensah', 'Frimpong', 'Adjei', 'Boakye', 'Nti', 'Kyei', 'Sam', 'Asiedu', 'Boadu',
  'Darko', 'Tetteh', 'Ansah', 'Appiah', 'Gyasi', 'Bonsu', 'Antwi', 'Sarpong', 'Quarshie', 'Amponsah',
];

const COURSE_SUBJECTS = [
  'Artificial Intelligence', 'Database Systems', 'Intro to Programming', 'Operating Systems',
  'Data Structures', 'Computer Networks', 'Software Engineering', 'Discrete Mathematics',
  'Web Development', 'Machine Learning', 'Object-Oriented Programming', 'Computer Architecture',
  'Mobile App Development', 'Theory of Computation', 'Algorithms', 'Cloud Computing',
  'Discrete Structures Lab', 'Cybersecurity Fundamentals', 'Distributed Systems', 'Digital Logic Design',
  'Human-Computer Interaction', 'Compilers', 'Computer Graphics', 'Information Retrieval',
  'Computer Vision', 'Natural Language Processing', 'Systems Programming', 'Wireless Networks',
  'Game Development', 'Data Mining', 'Robotics', 'Quantum Computing Intro',
  'Parallel Computing', 'Ethics in Computing', 'Numerical Methods', 'Bioinformatics',
  'Blockchain Fundamentals', 'DevOps Practices', 'Embedded Systems', 'Software Testing',
];

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
const REGULAR_TYPES = ['Assignment', 'Quiz', 'Project', 'Lab'];

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}
function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
function pad(n, width) {
  return String(n).padStart(width, '0');
}
function addDays(dateStr, days) {
  const d = new Date(dateStr + 'T00:00:00Z');
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}
function daysBetween(a, b) {
  return Math.round((new Date(b) - new Date(a)) / 86400000);
}

// 2 completed past semesters, 1 current (in progress), 1 future (nothing
// due yet) - relative to "today" per the environment (2026-08-15).
const SEMESTERS = [
  { id: 'SEM11', start: '2025-09-01', end: '2025-12-15', phase: 'past' },
  { id: 'SEM12', start: '2026-01-12', end: '2026-05-01', phase: 'past' },
  { id: 'SEM13', start: '2026-09-01', end: '2026-12-15', phase: 'current' },
  { id: 'SEM14', start: '2027-01-12', end: '2027-05-01', phase: 'future' },
];

async function batchInsert(conn, sql, rows, chunkSize = 300) {
  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize);
    const placeholders = chunk.map(() => `(${chunk[0].map(() => '?').join(',')})`).join(',');
    const flat = chunk.flat();
    await conn.query(`${sql} VALUES ${placeholders}`, flat);
  }
}

async function main() {
  await withRole('admin_role', async (conn) => {
    console.log('--- Wiping existing course-dependent data ---');
    await conn.query('DELETE FROM SUBMISSION_AUDIT_LOG');
    await conn.query('DELETE FROM SUBMISSION');
    await conn.query('DELETE FROM ATTENDANCE');
    await conn.query('DELETE FROM ENROLLMENT');
    await conn.query('DELETE FROM ASSESSMENT');
    await conn.query('DELETE FROM TIMETABLE');
    await conn.query('DELETE FROM COURSE');
    console.log('Wiped.');

    console.log('--- Topping up lecturers/students to L030/S050 (skipping any that already exist) ---');
    const passwordHash = await bcrypt.hash(PASSWORD, BCRYPT_ROUNDS);

    const [existingLecturers] = await conn.execute('SELECT LecturerID FROM Lecturer');
    const existingLecturerIds = new Set(existingLecturers.map((r) => r.LecturerID));
    const [existingStudents] = await conn.execute('SELECT StudentID FROM STUDENT');
    const existingStudentIds = new Set(existingStudents.map((r) => r.StudentID));
    const [existingUsers] = await conn.execute('SELECT UserID FROM APP_USER');
    const existingUserIds = new Set(existingUsers.map((r) => r.UserID));

    function nextUserId(prefix) {
      let n = 1;
      while (existingUserIds.has(`U${pad(n, 3)}`)) n++;
      existingUserIds.add(`U${pad(n, 3)}`);
      return `U${pad(n, 3)}`;
    }

    for (let i = 1; i <= 30; i++) {
      const lecturerId = `L${pad(i, 3)}`;
      if (existingLecturerIds.has(lecturerId)) continue;
      await conn.query('CALL sp_create_lecturer(?, ?, ?, ?, ?, ?, ?)', [
        nextUserId(), lecturerId, `${lecturerId.toLowerCase()}@slms.edu`, passwordHash,
        pick(FIRST_NAMES), pick(LAST_NAMES), '1980-01-01',
      ]);
    }
    for (let i = 1; i <= 50; i++) {
      const studentId = `S${pad(i, 3)}`;
      if (existingStudentIds.has(studentId)) continue;
      await conn.query('CALL sp_create_student(?, ?, ?, ?, ?, ?, ?)', [
        nextUserId(), studentId, `${studentId.toLowerCase()}@slms.edu`, passwordHash,
        pick(FIRST_NAMES), pick(LAST_NAMES), '2003-01-01',
      ]);
    }
    console.log('Topped up.');

    // 30 lecturers total. 15 teach 1 course, 10 teach 2, 5 teach 3 -> 55 courses.
    const lecturerIds = Array.from({ length: 30 }, (_, i) => `L${pad(i + 1, 3)}`);
    const courseCounts = [
      ...Array(15).fill(1),
      ...Array(10).fill(2),
      ...Array(5).fill(3),
    ];
    console.log('--- Creating 55 courses across 30 lecturers and 4 semesters ---');
    const courses = [];
    let courseNum = 1;
    for (let i = 0; i < lecturerIds.length; i++) {
      for (let c = 0; c < courseCounts[i]; c++) {
        const courseId = `C${pad(courseNum, 3)}`;
        const semester = SEMESTERS[(courseNum - 1) % SEMESTERS.length];
        const subject = COURSE_SUBJECTS[(courseNum - 1) % COURSE_SUBJECTS.length];
        courses.push({
          courseId,
          courseName: subject,
          courseCode: `CS${pad(courseNum, 3)}`,
          creditHours: pick([3, 3, 3, 4]),
          lecturerId: lecturerIds[i],
          semester,
        });
        courseNum++;
      }
    }
    await batchInsert(
      conn,
      'INSERT INTO COURSE (CourseID, CourseName, CourseCode, CreditHours, LecturerID, SemesterID)',
      courses.map((c) => [c.courseId, c.courseName, c.courseCode, c.creditHours, c.lecturerId, c.semester.id])
    );
    console.log(`Created ${courses.length} courses.`);

    console.log('--- Creating one timetable session per course ---');
    const timetableRows = courses.map((c, i) => [
      `T${pad(i + 1, 3)}`, c.courseId, pick(DAYS), `${pad(randInt(8, 15), 2)}:00:00`, `${pad(randInt(16, 18), 2)}:00:00`,
      `Room ${randInt(101, 320)}`,
    ]);
    await batchInsert(
      conn,
      'INSERT INTO TIMETABLE (TimetableID, CourseID, DayOfWeek, StartTime, EndTime, Room)',
      timetableRows
    );
    const timetableByCourse = new Map(timetableRows.map((r) => [r[1], r[0]]));
    console.log(`Created ${timetableRows.length} timetable rows.`);

    console.log('--- Enrolling 6-12 students per course ---');
    const studentIds = Array.from({ length: 50 }, (_, i) => `S${pad(i + 1, 3)}`);
    const enrollmentsByCourse = new Map();
    for (const c of courses) {
      const count = randInt(6, 12);
      const shuffled = [...studentIds].sort(() => Math.random() - 0.5);
      const chosen = shuffled.slice(0, count);
      enrollmentsByCourse.set(c.courseId, chosen);
      for (const studentId of chosen) {
        await conn.query('CALL sp_enroll_student(?, ?)', [studentId, c.courseId]);
      }
    }
    console.log('Enrolled.');

    console.log('--- Creating assessments (1 Midsem + 1 Final + 2-4 Regular per course) ---');
    let assessmentNum = 1;
    const assessments = []; // { assessmentId, courseId, category, maxScore, dueDate }
    for (const c of courses) {
      const span = daysBetween(c.semester.start, c.semester.end);
      const midDate = addDays(c.semester.start, Math.round(span * 0.45));
      const finalDate = addDays(c.semester.start, Math.round(span * 0.95));

      const midsemId = `AS${pad(assessmentNum++, 4)}`;
      assessments.push({ assessmentId: midsemId, courseId: c.courseId, category: 'Midsem', type: 'Exam', name: `${c.courseName} Midsem`, maxScore: 100, dueDate: midDate });

      const finalId = `AS${pad(assessmentNum++, 4)}`;
      assessments.push({ assessmentId: finalId, courseId: c.courseId, category: 'Final', type: 'Exam', name: `${c.courseName} Final`, maxScore: 100, dueDate: finalDate });

      const regularCount = randInt(2, 4);
      for (let r = 0; r < regularCount; r++) {
        const regId = `AS${pad(assessmentNum++, 4)}`;
        const dueOffset = Math.round(span * ((r + 1) / (regularCount + 1)));
        assessments.push({
          assessmentId: regId, courseId: c.courseId, category: 'Regular', type: pick(REGULAR_TYPES),
          name: `${pick(REGULAR_TYPES)} ${r + 1}`, maxScore: pick([20, 25, 50, 100]), dueDate: addDays(c.semester.start, dueOffset),
        });
      }
    }
    await batchInsert(
      conn,
      'INSERT INTO ASSESSMENT (AssessmentID, CourseID, AssessmentType, AssessmentName, MaxScore, DueDate, AssessmentCategory)',
      assessments.map((a) => [a.assessmentId, a.courseId, a.type, a.name, a.maxScore, a.dueDate, a.category])
    );
    console.log(`Created ${assessments.length} assessments.`);

    console.log('--- Generating submissions + attendance (this is the slow part) ---');
    const today = '2026-08-15';
    let subNum = 1;
    const submissionRows = [];
    const assessmentsByCourse = new Map();
    for (const a of assessments) {
      if (!assessmentsByCourse.has(a.courseId)) assessmentsByCourse.set(a.courseId, []);
      assessmentsByCourse.get(a.courseId).push(a);
    }

    for (const c of courses) {
      const students = enrollmentsByCourse.get(c.courseId);
      const courseAssessments = assessmentsByCourse.get(c.courseId);

      for (const studentId of students) {
        for (const a of courseAssessments) {
          if (c.semester.phase === 'future') continue; // nothing due yet, no submissions at all

          let willSubmit = true;
          let willGrade = true;
          if (c.semester.phase === 'current') {
            willSubmit = Math.random() < 0.7;
            willGrade = willSubmit && Math.random() < 0.7;
          }
          if (!willSubmit) continue;

          const pct = 0.35 + Math.random() * 0.65; // 35%-100%, gives spread across every letter band
          const score = willGrade ? Math.round(a.maxScore * pct * 100) / 100 : null;

          // Occasionally late, mostly on time - gives vw_late_submissions real rows.
          const lateBias = Math.random() < 0.15 ? randInt(1, 10) : -randInt(0, 5);
          let subDate = addDays(a.dueDate, lateBias);
          if (c.semester.phase === 'current' && subDate > today) subDate = today;

          submissionRows.push([`SUB${pad(subNum++, 5)}`, a.assessmentId, studentId, subDate, score, 1]);
        }
      }
    }
    await batchInsert(
      conn,
      'INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)',
      submissionRows
    );
    console.log(`Created ${submissionRows.length} submissions.`);

    let attNum = 1;
    const attendanceRows = [];
    for (const c of courses) {
      if (c.semester.phase === 'future') continue; // no sessions have happened yet
      const students = enrollmentsByCourse.get(c.courseId);
      const timetableId = timetableByCourse.get(c.courseId);
      const span = daysBetween(c.semester.start, c.semester.phase === 'current' ? today : c.semester.end);
      const sessionCount = Math.min(10, Math.max(1, Math.floor(span / 7)));

      for (const studentId of students) {
        const usedDates = new Set();
        for (let s = 0; s < sessionCount; s++) {
          let date = addDays(c.semester.start, s * 7 + randInt(0, 3));
          if (date > today) date = today;
          if (usedDates.has(date)) continue;
          usedDates.add(date);
          const roll = Math.random();
          const status = roll < 0.75 ? 'Present' : roll < 0.9 ? 'Absent' : 'Late';
          attendanceRows.push([`ATT${pad(attNum++, 5)}`, studentId, timetableId, date, status]);
        }
      }
    }
    await batchInsert(
      conn,
      'INSERT INTO ATTENDANCE (AttendanceID, StudentID, TimetableID, AttendanceDate, Status)',
      attendanceRows
    );
    console.log(`Created ${attendanceRows.length} attendance rows.`);

    console.log('--- Done ---');
  });
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
