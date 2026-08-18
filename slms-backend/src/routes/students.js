const express = require('express');
const {
  getTranscript,
  getTimetable,
  getAttendance,
  getAssessments,
  getBelowClassAverage,
  getUpcomingDeadlines,
  getAllStudents,
  getAttendanceRecords,
} = require('../controllers/studentsController');
const { enrollStudent, unenrollStudent } = require('../controllers/enrollmentsController');
const { createStudent } = require('../controllers/usersController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

router.post('/', requireAuth, requireRole('Admin'), createStudent);

// Declared before /:studentId/... so it isn't captured as a studentId, same
// ordering reason as GET /api/lecturers/load. Admin-only directory.
router.get('/', requireAuth, requireRole('Admin'), getAllStudents);

router.get('/:studentId/transcript', requireAuth, getTranscript);
router.get('/:studentId/timetable', requireAuth, getTimetable);
router.get('/:studentId/attendance', requireAuth, getAttendance);
router.get('/:studentId/attendance-records', requireAuth, getAttendanceRecords);
router.get('/:studentId/assessments', requireAuth, getAssessments);
router.get('/:studentId/below-average', requireAuth, getBelowClassAverage);
router.get('/:studentId/upcoming-deadlines', requireAuth, getUpcomingDeadlines);
router.post('/:studentId/enrollments', requireAuth, requireRole('Admin'), enrollStudent);
// Not admin-only: a student may drop their own enrolment. Ownership (self or
// Admin, Lecturer refused) is enforced in the controller via canReadStudent.
router.delete('/:studentId/enrollments/:courseId', requireAuth, unenrollStudent);

module.exports = router;
