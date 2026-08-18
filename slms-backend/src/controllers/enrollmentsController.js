const { withRole } = require('../db');
const { canReadStudent } = require('../auth/access');

// Enrolment is admin-only, so the route guard handles authorization and this
// controller does not repeat a per-user ownership check.
async function enrollStudent(req, res, next) {
  try {
    const { studentId } = req.params;
    const { courseId } = req.body || {};

    if (typeof courseId !== 'string' || courseId.trim() === '') {
      return res.status(400).json({ error: 'courseId is required.' });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      // Checked up front so a bad ID reads as 404 rather than surfacing a
      // foreign-key error as a generic 500.
      const [students] = await conn.execute(
        'SELECT StudentID FROM STUDENT WHERE StudentID = ?',
        [studentId]
      );
      if (students.length === 0) return { notFound: 'student' };

      const [courses] = await conn.execute('SELECT CourseID FROM COURSE WHERE CourseID = ?', [
        courseId,
      ]);
      if (courses.length === 0) return { notFound: 'course' };

      // The procedure blocks duplicates and generates the EnrollmentID itself.
      await conn.query('CALL sp_enroll_student(?, ?)', [studentId, courseId]);

      // Read back the row the procedure created, since it returns nothing.
      const [rows] = await conn.execute(
        `SELECT EnrollmentID, StudentID, CourseID, EnrollmentDate
           FROM ENROLLMENT
          WHERE StudentID = ? AND CourseID = ?`,
        [studentId, courseId]
      );
      return { enrollment: rows[0] };
    });

    if (outcome.notFound === 'student') {
      return res.status(404).json({ error: `No student found with ID ${studentId}.` });
    }
    if (outcome.notFound === 'course') {
      return res.status(404).json({ error: `No course found with ID ${courseId}.` });
    }

    const e = outcome.enrollment;
    return res.status(201).json({
      enrollmentId: e.EnrollmentID,
      studentId: e.StudentID,
      courseId: e.CourseID,
      enrollmentDate: e.EnrollmentDate,
    });
  } catch (err) {
    // sp_enroll_student raises only one 45000: already enrolled. That is a
    // conflict with existing state, not malformed input, so 409 rather than 400.
    if (err.sqlState === '45000') {
      return res.status(409).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

async function unenrollStudent(req, res, next) {
  try {
    const { studentId, courseId } = req.params;

    if (!canReadStudent(req.user, studentId)) {
      return res.status(403).json({ error: 'Not permitted to unenroll this student.' });
    }

    await withRole(req.user.dbRole, (conn) =>
      conn.query('CALL sp_unenroll_student(?, ?)', [studentId, courseId])
    );

    return res.status(204).send();
  } catch (err) {
    // sp_unenroll_student raises only one 45000: no matching enrolment.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

module.exports = { enrollStudent, unenrollStudent };
