const { withRole } = require('../db');

const WEEKDAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const TIME_PATTERN = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

// Admin-only: scheduling/room management is a registrar function, not a
// faculty one.
async function updateTimetable(req, res, next) {
  try {
    const { timetableId } = req.params;
    const { dayOfWeek, startTime, endTime, room } = req.body || {};

    if (!WEEKDAYS.includes(dayOfWeek)) {
      return res.status(400).json({ error: `dayOfWeek must be one of: ${WEEKDAYS.join(', ')}.` });
    }
    if (typeof startTime !== 'string' || !TIME_PATTERN.test(startTime)) {
      return res.status(400).json({ error: 'startTime is required in HH:MM format.' });
    }
    if (typeof endTime !== 'string' || !TIME_PATTERN.test(endTime)) {
      return res.status(400).json({ error: 'endTime is required in HH:MM format.' });
    }
    if (endTime <= startTime) {
      return res.status(400).json({ error: 'endTime must be after startTime.' });
    }
    if (typeof room !== 'string' || room.trim() === '') {
      return res.status(400).json({ error: 'room is required.' });
    }

    const updated = await withRole(req.user.dbRole, async (conn) => {
      await conn.query('CALL sp_update_timetable(?, ?, ?, ?, ?)', [
        timetableId,
        dayOfWeek,
        startTime,
        endTime,
        room,
      ]);

      const [rows] = await conn.execute(
        `SELECT t.TimetableID, t.CourseID, t.DayOfWeek, t.StartTime, t.EndTime, t.Room,
                c.CourseCode, c.CourseName
           FROM TIMETABLE t
           JOIN COURSE c ON t.CourseID = c.CourseID
          WHERE t.TimetableID = ?`,
        [timetableId]
      );
      return rows[0];
    });

    return res.json({
      timetableId: updated.TimetableID,
      courseId: updated.CourseID,
      courseCode: updated.CourseCode,
      courseName: updated.CourseName,
      dayOfWeek: updated.DayOfWeek,
      startTime: updated.StartTime,
      endTime: updated.EndTime,
      room: updated.Room,
    });
  } catch (err) {
    // sp_update_timetable raises only one 45000: unknown TimetableID.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

module.exports = { updateTimetable };
