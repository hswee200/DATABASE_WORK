const { withRole } = require('../db');
const { canReadCourse } = require('../auth/access');

async function getRoster(req, res, next) {
  try {
    const { courseId } = req.params;

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      // Course details come from COURSE/Lecturer rather than the roster view,
      // which joins ENROLLMENT and so returns nothing for a course with no
      // students enrolled yet. This also resolves ownership for the check below.
      const [courses] = await conn.execute(
        `SELECT c.CourseID, c.CourseName, c.CourseCode, c.LecturerID,
                l.F_Name AS LecturerFirstName, l.L_Name AS LecturerLastName
           FROM COURSE c
           JOIN Lecturer l ON c.LecturerID = l.LecturerID
          WHERE c.CourseID = ?`,
        [courseId]
      );
      if (courses.length === 0) return { notFound: true };

      const course = courses[0];

      // Only students need an enrolment lookup; skip the query for everyone else.
      let isEnrolled = false;
      if (req.user.roleName === 'Student') {
        const [enrolments] = await conn.execute(
          'SELECT EnrollmentID FROM ENROLLMENT WHERE StudentID = ? AND CourseID = ?',
          [req.user.username, courseId]
        );
        isEnrolled = enrolments.length > 0;
      }

      if (!canReadCourse(req.user, course.LecturerID, isEnrolled)) return { forbidden: true };

      const [rows] = await conn.execute(
        `SELECT StudentID, StudentFirstName, StudentLastName, EnrollmentDate
           FROM VW_COURSE_ROSTER
          WHERE CourseID = ?
          ORDER BY StudentID`,
        [courseId]
      );

      // Included alongside the roster (rather than a separate endpoint) so
      // the Admin course-context Timetable tab knows which TimetableID(s)
      // belong to this course - nothing else currently exposes that by course.
      const [timetableRows] = await conn.execute(
        `SELECT TimetableID, DayOfWeek, StartTime, EndTime, Room
           FROM TIMETABLE
          WHERE CourseID = ?
          ORDER BY StartTime`,
        [courseId]
      );

      return { course, rows, timetableRows };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No course found with ID ${courseId}.` });
    }
    if (outcome.forbidden) {
      return res.status(403).json({ error: 'Not permitted to view the roster for this course.' });
    }

    const { course, rows, timetableRows } = outcome;
    return res.json({
      courseId: course.CourseID,
      courseCode: course.CourseCode,
      courseName: course.CourseName,
      lecturer: {
        lecturerId: course.LecturerID,
        firstName: course.LecturerFirstName,
        lastName: course.LecturerLastName,
      },
      enrolledCount: rows.length,
      students: rows.map((row) => ({
        studentId: row.StudentID,
        firstName: row.StudentFirstName,
        lastName: row.StudentLastName,
        enrollmentDate: row.EnrollmentDate,
      })),
      timetable: timetableRows.map((row) => ({
        timetableId: row.TimetableID,
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

async function courseExists(conn, courseId) {
  const [rows] = await conn.execute('SELECT CourseID FROM COURSE WHERE CourseID = ?', [courseId]);
  return rows.length > 0;
}

// Admin-only, no Lecturer/Student path: reassigning a course to a different
// lecturer is a registrar function (scheduling/staffing), not an academic one.
async function reassignCourseLecturer(req, res, next) {
  try {
    const { courseId } = req.params;
    const { lecturerId } = req.body || {};

    if (typeof lecturerId !== 'string' || lecturerId.trim() === '') {
      return res.status(400).json({ error: 'lecturerId is required.' });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      // Checked up front so a bad course ID reads as 404 rather than a silent
      // no-op update (the procedure itself does not verify CourseID exists).
      if (!(await courseExists(conn, courseId))) return { notFound: true };

      await conn.query('CALL sp_reassign_course_lecturer(?, ?)', [courseId, lecturerId]);

      const [rows] = await conn.execute(
        `SELECT c.CourseID, c.CourseCode, c.CourseName, c.LecturerID,
                l.F_Name AS LecturerFirstName, l.L_Name AS LecturerLastName
           FROM COURSE c
           JOIN Lecturer l ON c.LecturerID = l.LecturerID
          WHERE c.CourseID = ?`,
        [courseId]
      );
      return { course: rows[0] };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No course found with ID ${courseId}.` });
    }

    const c = outcome.course;
    return res.json({
      courseId: c.CourseID,
      courseCode: c.CourseCode,
      courseName: c.CourseName,
      lecturerId: c.LecturerID,
      lecturerFirstName: c.LecturerFirstName,
      lecturerLastName: c.LecturerLastName,
    });
  } catch (err) {
    // sp_reassign_course_lecturer raises only one 45000: unknown lecturer.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

// Admin-only: the entry point for the Courses browse page, since Admin has
// no "my courses" the way Student/Lecturer do.
async function listCourses(req, res, next) {
  try {
    const rows = await withRole(req.user.dbRole, async (conn) => {
      const [result] = await conn.execute(
        `SELECT c.CourseID, c.CourseCode, c.CourseName, c.LecturerID,
                l.F_Name AS LecturerFirstName, l.L_Name AS LecturerLastName,
                s.SemesterName, s.AcademicYear
           FROM COURSE c
           JOIN Lecturer l  ON c.LecturerID = l.LecturerID
           JOIN SEMESTER s ON c.SemesterID = s.SemesterID
          ORDER BY c.CourseCode`
      );
      return result;
    });

    return res.json({
      courses: rows.map((row) => ({
        courseId: row.CourseID,
        courseCode: row.CourseCode,
        courseName: row.CourseName,
        lecturerId: row.LecturerID,
        lecturerFirstName: row.LecturerFirstName,
        lecturerLastName: row.LecturerLastName,
        semesterName: row.SemesterName,
        academicYear: row.AcademicYear,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getRoster, reassignCourseLecturer, listCourses };
