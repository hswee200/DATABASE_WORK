const { withRole } = require('../db');
const { canReadLecturer } = require('../auth/access');
const { WEEKDAY_ORDER } = require('../constants');

async function getTimetable(req, res, next) {
  try {
    const { lecturerId } = req.params;

    if (!canReadLecturer(req.user, lecturerId)) {
      return res.status(403).json({ error: 'Not permitted to view this timetable.' });
    }

    const sessions = await withRole(req.user.dbRole, async (conn) => {
      const [lecturers] = await conn.execute(
        'SELECT LecturerID FROM Lecturer WHERE LecturerID = ?',
        [lecturerId]
      );
      if (lecturers.length === 0) return null;

      // This view exposes semester columns the student view does not, so they
      // are passed through rather than dropped for symmetry. Joined to
      // TIMETABLE (matching course + day + start time) to also expose
      // TimetableID, which the view itself does not carry - needed so
      // course-context pages (Mark Attendance, course Timetable) know which
      // session they're acting on.
      const [rows] = await conn.execute(
        `SELECT v.CourseID, v.CourseCode, v.CourseName, v.SemesterName, v.AcademicYear,
                v.DayOfWeek, v.StartTime, v.EndTime, v.Room, t.TimetableID
           FROM VW_LECTURER_TIMETABLE v
           JOIN TIMETABLE t
             ON t.CourseID = v.CourseID
            AND t.DayOfWeek = v.DayOfWeek
            AND t.StartTime = v.StartTime
          WHERE v.LecturerID = ?
          -- WEEKDAY_ORDER's "DayOfWeek" is unqualified and would be ambiguous
          -- now that both v and t carry that column, so it's qualified here
          -- rather than changed at the shared constant (fine everywhere else).
          ORDER BY ${WEEKDAY_ORDER.replace('DayOfWeek', 'v.DayOfWeek')}, v.StartTime`,
        [lecturerId]
      );
      return rows;
    });

    if (sessions === null) {
      return res.status(404).json({ error: `No lecturer found with ID ${lecturerId}.` });
    }

    return res.json({
      lecturerId,
      timetable: sessions.map((row) => ({
        timetableId: row.TimetableID,
        courseId: row.CourseID,
        courseCode: row.CourseCode,
        courseName: row.CourseName,
        semesterName: row.SemesterName,
        academicYear: row.AcademicYear,
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

function mapLoad(row) {
  return {
    lecturerId: row.LecturerID,
    firstName: row.F_Name,
    lastName: row.L_Name,
    // COUNT columns arrive as BIGINT; normalise so clients always get numbers.
    numCourses: Number(row.NumCourses),
    numStudents: Number(row.NumStudents),
  };
}

async function getLoad(req, res, next) {
  try {
    const { lecturerId } = req.params;

    if (!canReadLecturer(req.user, lecturerId)) {
      return res.status(403).json({ error: 'Not permitted to view this teaching load.' });
    }

    const row = await withRole(req.user.dbRole, async (conn) => {
      const [rows] = await conn.execute(
        `SELECT LecturerID, F_Name, L_Name, NumCourses, NumStudents
           FROM VW_LECTURER_LOAD
          WHERE LecturerID = ?`,
        [lecturerId]
      );
      return rows[0] || null;
    });

    // The view LEFT JOINs from Lecturer, so every lecturer appears even with no
    // courses. A missing row therefore means the lecturer does not exist.
    if (row === null) {
      return res.status(404).json({ error: `No lecturer found with ID ${lecturerId}.` });
    }

    return res.json(mapLoad(row));
  } catch (err) {
    return next(err);
  }
}

// Admin-only overview across all lecturers, for staffing at a glance.
async function getAllLoad(req, res, next) {
  try {
    const rows = await withRole(req.user.dbRole, (conn) =>
      conn
        .execute(
          `SELECT LecturerID, F_Name, L_Name, NumCourses, NumStudents
             FROM VW_LECTURER_LOAD
            ORDER BY NumStudents DESC, LecturerID`
        )
        .then(([result]) => result)
    );

    return res.json({ lecturers: rows.map(mapLoad) });
  } catch (err) {
    return next(err);
  }
}

// Admin-only directory: LecturerID, F_Name, L_Name only, no stats. Distinct
// from getAllLoad above - that's course-load reporting, this is the plain
// name list Reassign Lecturer's dropdown needs.
async function getAllLecturers(req, res, next) {
  try {
    const rows = await withRole(req.user.dbRole, (conn) =>
      conn
        .execute('SELECT LecturerID, F_Name, L_Name FROM Lecturer ORDER BY F_Name, L_Name')
        .then(([result]) => result)
    );

    return res.json({
      lecturers: rows.map((row) => ({
        lecturerId: row.LecturerID,
        firstName: row.F_Name,
        lastName: row.L_Name,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getTimetable, getLoad, getAllLoad, getAllLecturers };
