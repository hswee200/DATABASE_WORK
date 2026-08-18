const express = require('express');
const { getAdminReports } = require('../controllers/reportsController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

// Admin-only oversight views - institution-wide, no per-user scoping.
router.get('/', requireAuth, requireRole('Admin'), getAdminReports);

module.exports = router;
