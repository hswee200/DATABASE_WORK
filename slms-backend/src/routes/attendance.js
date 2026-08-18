const express = require('express');
const {
  updateAttendanceStatus,
  deleteAttendance,
  markAttendance,
} = require('../controllers/attendanceController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

// Lecturer-only; per-course ownership is checked in the controller.
router.post('/', requireAuth, requireRole('Lecturer'), markAttendance);
router.put('/:attendanceId/status', requireAuth, requireRole('Lecturer'), updateAttendanceStatus);
router.delete('/:attendanceId', requireAuth, requireRole('Admin'), deleteAttendance);

module.exports = router;
