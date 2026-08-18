const express = require('express');
const { updateTimetable } = require('../controllers/timetableController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

router.put('/:timetableId', requireAuth, requireRole('Admin'), updateTimetable);

module.exports = router;
