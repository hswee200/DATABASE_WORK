const express = require('express');
const { createAdmin } = require('../controllers/usersController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

// Creating an admin grants full application privileges, so only an existing
// admin may do it.
router.post('/', requireAuth, requireRole('Admin'), createAdmin);

module.exports = router;
