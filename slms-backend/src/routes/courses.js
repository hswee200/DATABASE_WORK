const express = require('express');
const { getRoster, reassignCourseLecturer, listCourses } = require('../controllers/coursesController');
const { createAssessment, getCourseAssessments, getCourseGrades } = require('../controllers/assessmentsController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

// Admin-only, mounted before the /:courseId routes so it isn't shadowed by
// them (same ordering reason as GET /api/lecturers/load).
router.get('/', requireAuth, requireRole('Admin'), listCourses);

// Read-only for every role. Access is decided in the controller rather than by
// requireRole, since both the lecturer and student cases depend on a per-course
// relationship (owns it / is enrolled in it) that requireRole cannot express.
router.get('/:courseId/roster', requireAuth, getRoster);
router.get('/:courseId/assessments', requireAuth, getCourseAssessments);
router.get('/:courseId/grades', requireAuth, getCourseGrades);

// Lecturer-only; per-course ownership is checked in the controller.
router.post('/:courseId/assessments', requireAuth, requireRole('Lecturer'), createAssessment);

// Admin-only: reassigning a course's lecturer is a registrar/scheduling
// action, not an academic one.
router.put('/:courseId/lecturer', requireAuth, requireRole('Admin'), reassignCourseLecturer);

module.exports = router;
