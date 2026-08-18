const express = require('express');
const { getTimetable, getLoad, getAllLoad, getAllLecturers } = require('../controllers/lecturersController');
const { createLecturer } = require('../controllers/usersController');
const { getLecturerReports } = require('../controllers/reportsController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

router.post('/', requireAuth, requireRole('Admin'), createLecturer);

// Declared before the parameterised routes so "load"/"" are not captured as
// a lecturerId. Express matches in definition order.
router.get('/load', requireAuth, requireRole('Admin'), getAllLoad);
router.get('/', requireAuth, requireRole('Admin'), getAllLecturers);

router.get('/:lecturerId/timetable', requireAuth, getTimetable);
router.get('/:lecturerId/load', requireAuth, getLoad);
router.get('/:lecturerId/reports', requireAuth, getLecturerReports);

module.exports = router;
