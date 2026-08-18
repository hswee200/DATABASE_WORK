const express = require('express');
const {
  recordGrade,
  submitAssessment,
  resubmitAssessment,
  deleteSubmission,
  getUngradedSubmissions,
} = require('../controllers/submissionsController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

// Declared before the parameterised routes so "ungraded" is not captured as
// a submissionId. Lecturer-only, own record - filtered by req.user.username
// in the controller, same as the student submit/resubmit pattern below.
router.get('/ungraded', requireAuth, requireRole('Lecturer'), getUngradedSubmissions);

// Lecturer-only, no Admin exception: grading is an academic judgment call,
// not an administrative one (see canModifyCourseContent). The per-course
// ownership check happens in the controller, where the submission is resolved.
router.put('/:submissionId/grade', requireAuth, requireRole('Lecturer'), recordGrade);
router.post('/submit', requireAuth, requireRole('Student'), submitAssessment);
router.post('/resubmit', requireAuth, requireRole('Student'), resubmitAssessment);
router.delete('/:submissionId', requireAuth, requireRole('Admin'), deleteSubmission);

module.exports = router;
