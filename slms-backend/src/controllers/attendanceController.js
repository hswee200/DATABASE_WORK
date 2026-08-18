const { withRole } = require('../db');
const { canModifyCourseContent } = require('../auth/access');

const VALID_STATUSES = ['Present', 'Absent', 'Late'];

async function loadAttendanceContext(conn, attendanceId) {
  const [rows] = await conn.execute(
    `SELECT att.AttendanceID, att.StudentID, att.AttendanceDate, c.LecturerID,
            c.CourseID, c.CourseName, s.F_Name AS StudentFirstName, s.L_Name AS StudentLastName
       FROM ATTENDANCE att
       JOIN TIMETABLE t ON att.TimetableID = t.TimetableID
       JOIN COURSE    c ON t.CourseID     = c.CourseID
       JOIN STUDENT   s ON att.StudentID  = s.StudentID
      WHERE att.AttendanceID = ?`,
    [attendanceId]
  );
  return rows[0] || null;
}

// Lecturer-only, own course's session only - correcting a Present/Absent/Late
// mark is an academic judgment call, not an administrative one. No Admin
// exception (see canModifyCourseContent).
async function updateAttendanceStatus(req, res, next) {
  try {
    const { attendanceId } = req.params;
    const { status } = req.body || {};

    if (!VALID_STATUSES.includes(status)) {
      return res
        .status(400)
        .json({ error: `status must be one of: ${VALID_STATUSES.join(', ')}.` });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const context = await loadAttendanceContext(conn, attendanceId);
      if (!context) return { notFound: true };

      if (!canModifyCourseContent(req.user, context.LecturerID)) return { forbidden: true };

      await conn.query('CALL sp_update_attendance_status(?, ?)', [attendanceId, status]);

      return { attendanceId, status, context };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No attendance record found with ID ${attendanceId}.` });
    }
    if (outcome.forbidden) {
      return res.status(403).json({ error: 'Not permitted to edit this attendance record.' });
    }

    const { context } = outcome;
    return res.json({
      attendanceId: outcome.attendanceId,
      status: outcome.status,
      studentId: context.StudentID,
      studentFirstName: context.StudentFirstName,
      studentLastName: context.StudentLastName,
      courseId: context.CourseID,
      courseName: context.CourseName,
    });
  } catch (err) {
    return next(err);
  }
}

async function deleteAttendance(req, res, next) {
  try {
    const { attendanceId } = req.params;

    // Looked up before the delete so the response can name what was removed
    // instead of just echoing back the ID the admin typed.
    const context = await withRole(req.user.dbRole, async (conn) => {
      const found = await loadAttendanceContext(conn, attendanceId);
      await conn.query('CALL sp_delete_attendance(?)', [attendanceId]);
      return found;
    });

    return res.json({
      attendanceId,
      deleted: true,
      studentId: context?.StudentID ?? null,
      studentFirstName: context?.StudentFirstName ?? null,
      studentLastName: context?.StudentLastName ?? null,
      courseId: context?.CourseID ?? null,
      courseName: context?.CourseName ?? null,
      attendanceDate: context?.AttendanceDate ?? null,
    });
  } catch (err) {
    // sp_delete_attendance raises only one 45000: unknown AttendanceID.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

// Lecturer-only, own course's session only - recording that a specific
// student was present/absent/late for a session is the academic act itself
// (no Admin exception, same reasoning as canModifyCourseContent elsewhere).
async function markAttendance(req, res, next) {
  try {
    const { studentId, timetableId, attendanceDate, status } = req.body || {};

    if (typeof studentId !== 'string' || studentId.trim() === '') {
      return res.status(400).json({ error: 'studentId is required.' });
    }
    if (typeof timetableId !== 'string' || timetableId.trim() === '') {
      return res.status(400).json({ error: 'timetableId is required.' });
    }
    if (typeof attendanceDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(attendanceDate)) {
      return res.status(400).json({ error: 'attendanceDate is required in YYYY-MM-DD format.' });
    }
    if (!VALID_STATUSES.includes(status)) {
      return res
        .status(400)
        .json({ error: `status must be one of: ${VALID_STATUSES.join(', ')}.` });
    }

    const outcome = await withRole(req.user.dbRole, async (conn) => {
      const [rows] = await conn.execute(
        `SELECT t.TimetableID, c.LecturerID, c.CourseID, c.CourseName
           FROM TIMETABLE t
           JOIN COURSE c ON t.CourseID = c.CourseID
          WHERE t.TimetableID = ?`,
        [timetableId]
      );
      if (rows.length === 0) return { notFound: true };

      const session = rows[0];
      if (!canModifyCourseContent(req.user, session.LecturerID)) return { forbidden: true };

      // AttendanceID is never supplied by the caller - the procedure
      // generates it internally (same pattern as sp_enroll_student) and
      // returns it via a trailing SELECT.
      const [result] = await conn.query('CALL sp_mark_attendance(?, ?, ?, ?)', [
        studentId,
        timetableId,
        attendanceDate,
        status,
      ]);

      const [students] = await conn.execute(
        'SELECT F_Name, L_Name FROM STUDENT WHERE StudentID = ?',
        [studentId]
      );
      return { session, student: students[0], attendanceId: result[0][0].AttendanceID };
    });

    if (outcome.notFound) {
      return res.status(404).json({ error: `No timetable entry found with ID ${timetableId}.` });
    }
    if (outcome.forbidden) {
      return res.status(403).json({ error: 'Not permitted to mark attendance for this course.' });
    }

    return res.status(201).json({
      attendanceId: outcome.attendanceId,
      studentId,
      studentFirstName: outcome.student?.F_Name ?? null,
      studentLastName: outcome.student?.L_Name ?? null,
      courseId: outcome.session.CourseID,
      courseName: outcome.session.CourseName,
      attendanceDate,
      status,
    });
  } catch (err) {
    // sp_mark_attendance's IF branch (invalid status) is pre-validated above;
    // the trigger's duplicate-record 45000 is the one that can still reach here.
    if (err.sqlState === '45000') {
      return res.status(409).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

module.exports = { updateAttendanceStatus, deleteAttendance, markAttendance };
