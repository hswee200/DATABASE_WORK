const express = require('express');
const { updateAssessment } = require('../controllers/assessmentsController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

// Lecturer-only; per-course ownership is checked in the controller.
router.put('/:assessmentId', requireAuth, requireRole('Lecturer'), updateAssessment);

module.exports = router;
