const { withRole } = require('../db');
const { canReadStudent } = require('../auth/access');
const { WEEKDAY_ORDER } = require('../constants');

async function findStudent(conn, studentId) {
  const [rows] = await conn.execute(
    'SELECT StudentID, F_Name, L_Name FROM STUDENT WHERE StudentID = ?',
    [studentId]
  );
  return rows[0] || null;
}

async function studentExists(conn, studentId) {
  return (await findStudent(conn, studentId)) !== null;
}

async function getTranscript(req, res, next) {
  try {
    const { studentId } = req.params;

    if (!canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to view this transcript.' });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      // Looked up separately from the transcript query so the student's name
      // is still available for the heading even when they have no graded
      // rows yet.
      const student = await findStudent(conn, studentId);
      if (!student) return null;

      // Queried directly against the view (rather than via
      // sp_generate_transcript, whose fixed SELECT list predates
      // CreditHours/GradePoint) so the per-course rows carry what's needed
      // for GPA weighting alongside percent/letter grade.
      //
      // conn.query (text protocol), not conn.execute (binary prepared
      // statements) - this view's derived table mixes GROUP BY with window
      // functions, and MariaDB's prepared-statement path raises a spurious
      // "Invalid use of group function" (ER_INVALID_GROUP_FUNC_USE) against
      // that shape that the plain text protocol doesn't hit. mysql2's
      // query() still escapes the placeholder safely client-side.
      const [rows] = await conn.query(
        `SELECT SemesterID, SemesterName, AcademicYear, CourseID, CourseName,
                CreditHours, FinalGradePercent, LetterGrade, GradePoint
           FROM vw_student_final_grades
          WHERE StudentID = ?
          ORDER BY AcademicYear, SemesterName`,
        [studentId]
      );

      // Per-semester GPA and running CGPA - vw_student_gpa already computes
      // both (SemesterGPA is a plain per-semester aggregate, CGPA is a
      // cumulative window aggregate ordered by academic chronology). Same
      // conn.query reasoning as above.
      const [gpaRows] = await conn.query(
        `SELECT SemesterID, SemesterName, AcademicYear, SemesterGPA, CGPA
           FROM vw_student_gpa
          WHERE StudentID = ?
          ORDER BY AcademicYear, SemesterName`,
        [studentId]
      );

      return { student, rows, gpaRows };
    });

    if (outcome === null) {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }

    return res.json({
      studentId,
      firstName: outcome.student.F_Name,
      lastName: outcome.student.L_Name,
      transcript: outcome.rows.map((row) => ({
        semesterId: row.SemesterID,
        semesterName: row.SemesterName,
        academicYear: row.AcademicYear,
        courseId: row.CourseID,
        courseName: row.CourseName,
        creditHours: Number(row.CreditHours),
        // DECIMAL arrives as a string from the driver; clients want a number.
        finalGradePercent: row.FinalGradePercent === null ? null : Number(row.FinalGradePercent),
        letterGrade: row.LetterGrade,
        gradePoint: row.GradePoint === null ? null : Number(row.GradePoint),
      })),
      gpa: outcome.gpaRows.map((row) => ({
        semesterId: row.SemesterID,
        semesterName: row.SemesterName,
        academicYear: row.AcademicYear,
        semesterGPA: Number(row.SemesterGPA),
        cgpa: Number(row.CGPA),
      })),
    });
  } catch (err) {
    return next(err);
  }
}

async function getTimetable(req, res, next) {
  try {
    const { studentId } = req.params;

    if (!canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to view this timetable.' });
    }

    const sessions = await withRole(req.user.dbRole, async (conn) => {
      if (!(await studentExists(conn, studentId))) return null;

      // The view itself only exposes CourseCode, but every other student
      // endpoint (transcript, attendance, assessments, roster) keys on
      // CourseID - joined in here so a timetable row can link to those.
      const [rows] = await conn.execute(
        `SELECT c.CourseID, vw.CourseCode, vw.CourseName, vw.DayOfWeek,
                vw.StartTime, vw.EndTime, vw.Room
           FROM VW_STUDENT_TIMETABLE vw
           JOIN COURSE c ON c.CourseCode = vw.CourseCode
          WHERE vw.StudentID = ?
          ORDER BY ${WEEKDAY_ORDER}, vw.StartTime`,
        [studentId]
      );
      return rows;
    });

    if (sessions === null) {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }

    return res.json({
      studentId,
      timetable: sessions.map((row) => ({
        courseId: row.CourseID,
        courseCode: row.CourseCode,
        courseName: row.CourseName,
        dayOfWeek: row.DayOfWeek,
        startTime: row.StartTime,
        endTime: row.EndTime,
        room: row.Room,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

async function getAttendance(req, res, next) {
  try {
    const { studentId } = req.params;

    if (!canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to view this attendance record.' });
    }

    const rows = await withRole(req.user.dbRole, async (conn) => {
      if (!(await studentExists(conn, studentId))) return null;

      const [result] = await conn.execute(
        `SELECT CourseID, CourseName, TimesPresent, TimesAbsent, TimesLate,
                TotalSessions, AttendanceRate
           FROM VW_ATTENDANCE_SUMMARY
          WHERE StudentID = ?
          ORDER BY CourseID`,
        [studentId]
      );
      return result;
    });

    if (rows === null) {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }

    return res.json({
      studentId,
      attendance: rows.map((row) => ({
        courseId: row.CourseID,
        courseName: row.CourseName,
        timesPresent: Number(row.TimesPresent),
        timesAbsent: Number(row.TimesAbsent),
        timesLate: Number(row.TimesLate),
        totalSessions: Number(row.TotalSessions),
        attendanceRate: row.AttendanceRate === null ? null : Number(row.AttendanceRate),
      })),
    });
  } catch (err) {
    return next(err);
  }
}

async function getAssessments(req, res, next) {
  try {
    const { studentId } = req.params;

    if (!canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to view these assessments.' });
    }

    const rows = await withRole(req.user.dbRole, async (conn) => {
      if (!(await studentExists(conn, studentId))) return null;

      // Soonest due first, so an "upcoming work" list needs no client-side sort.
      // Joined to COURSE for CourseCode/CourseName - the view itself only
      // carries CourseID.
      const [result] = await conn.execute(
        `SELECT v.AssessmentID, v.AssessmentName, v.CourseID, v.DueDate, v.SubmissionID, v.Status,
                c.CourseCode, c.CourseName
           FROM VW_ASSESSMENT_STATUS v
           JOIN COURSE c ON v.CourseID = c.CourseID
          WHERE v.StudentID = ?
          ORDER BY v.DueDate, v.AssessmentID`,
        [studentId]
      );
      return result;
    });

    if (rows === null) {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }

    return res.json({
      studentId,
      assessments: rows.map((row) => ({
        assessmentId: row.AssessmentID,
        assessmentName: row.AssessmentName,
        courseId: row.CourseID,
        courseCode: row.CourseCode,
        courseName: row.CourseName,
        dueDate: row.DueDate,
        submissionId: row.SubmissionID,
        // 'Submitted' | 'Past-Due' | 'Upcoming', computed by the view.
        status: row.Status,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

// "How am I doing?" - per-course average vs. the class average, own record
// only. vw_below_class_average has no built-in "below" filter (a view can't
// take a parameter), so the StudentAvg < ClassAvg comparison happens here in
// the WHERE clause instead of in the view itself.
async function getBelowClassAverage(req, res, next) {
  try {
    const { studentId } = req.params;

    if (!canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to view this record.' });
    }

    const rows = await withRole(req.user.dbRole, async (conn) => {
      if (!(await studentExists(conn, studentId))) return null;

      const [result] = await conn.execute(
        `SELECT CourseID, CourseName, StudentAvg, ClassAvg
           FROM vw_below_class_average
          WHERE StudentID = ? AND StudentAvg < ClassAvg
          ORDER BY CourseID`,
        [studentId]
      );
      return result;
    });

    if (rows === null) {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }

    return res.json({
      studentId,
      belowAverage: rows.map((row) => ({
        courseId: row.CourseID,
        courseName: row.CourseName,
        studentAvg: row.StudentAvg === null ? null : Number(row.StudentAvg),
        classAvg: row.ClassAvg === null ? null : Number(row.ClassAvg),
      })),
    });
  } catch (err) {
    return next(err);
  }
}

// Upcoming deadlines ranked within each course, scoped to courses this
// student is actually enrolled in - the view itself is institution-wide.
async function getUpcomingDeadlines(req, res, next) {
  try {
    const { studentId } = req.params;

    if (!canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to view this record.' });
    }

    const rows = await withRole(req.user.dbRole, async (conn) => {
      if (!(await studentExists(conn, studentId))) return null;

      const [result] = await conn.execute(
        `SELECT * FROM vw_upcoming_deadlines_ranked
          WHERE CourseID IN (SELECT CourseID FROM ENROLLMENT WHERE StudentID = ?)
          ORDER BY CourseID, DeadlineRankInCourse`,
        [studentId]
      );
      return result;
    });

    if (rows === null) {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }

    return res.json({
      studentId,
      upcomingDeadlines: rows.map((row) => ({
        courseId: row.CourseID,
        courseName: row.CourseName,
        assessmentName: row.AssessmentName,
        dueDate: row.DueDate,
        daysRemaining: row.DaysRemaining,
        deadlineRankInCourse: row.DeadlineRankInCourse,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

// Admin-only directory, powers Transcript lookup's and Corrections'
// name search - nobody should have to already know a StudentID to find
// someone by name.
async function getAllStudents(req, res, next) {
  try {
    const rows = await withRole(req.user.dbRole, (conn) =>
      conn
        .execute('SELECT StudentID, F_Name, L_Name FROM STUDENT ORDER BY F_Name, L_Name')
        .then(([result]) => result)
    );

    return res.json({
      students: rows.map((row) => ({
        studentId: row.StudentID,
        firstName: row.F_Name,
        lastName: row.L_Name,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

// Raw per-row attendance (unlike getAttendance above, which only returns
// per-course aggregates) - powers Correct Attendance's and Corrections'
// record picker: search a student by name, then pick which dated record to
// act on, never a typed AttendanceID. Admin sees any student; a Lecturer
// only sees rows from courses they own (filtered in the query, not just
// checked - GRANT is table-level, this row-level boundary has to be
// enforced here); a Student sees only their own record.
async function getAttendanceRecords(req, res, next) {
  try {
    const { studentId } = req.params;
    const { courseId } = req.query;

    if (req.user.roleName !== 'Lecturer' && !canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to view this record.' });
    }

    const rows = await withRole(req.user.dbRole, async (conn) => {
      if (!(await studentExists(conn, studentId))) return null;

      const params = [studentId];
      let ownerFilter = '';
      if (req.user.roleName === 'Lecturer') {
        ownerFilter = 'AND c.LecturerID = ?';
        params.push(req.user.username);
      }
      let courseFilter = '';
      if (typeof courseId === 'string' && courseId.trim() !== '') {
        courseFilter = 'AND c.CourseID = ?';
        params.push(courseId);
      }

      const [result] = await conn.query(
        `SELECT att.AttendanceID, att.AttendanceDate, att.Status,
                c.CourseID, c.CourseName, t.TimetableID
           FROM ATTENDANCE att
           JOIN TIMETABLE t ON att.TimetableID = t.TimetableID
           JOIN COURSE c ON t.CourseID = c.CourseID
          WHERE att.StudentID = ? ${ownerFilter} ${courseFilter}
          ORDER BY att.AttendanceDate DESC`,
        params
      );
      return result;
    });

    if (rows === null) {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }

    return res.json({
      studentId,
      records: rows.map((row) => ({
        attendanceId: row.AttendanceID,
        attendanceDate: row.AttendanceDate,
        status: row.Status,
        courseId: row.CourseID,
        courseName: row.CourseName,
        timetableId: row.TimetableID,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getTranscript,
  getTimetable,
  getAttendance,
  getAssessments,
  getBelowClassAverage,
  getUpcomingDeadlines,
  getAllStudents,
  getAttendanceRecords,
};
