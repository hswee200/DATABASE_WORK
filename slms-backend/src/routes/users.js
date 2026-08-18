const express = require('express');
const { deactivateUser, reactivateUser, changeOwnPassword, getAllUsers } = require('../controllers/usersController');
const { requireAuth, requireRole } = require('../middleware/requireAuth');

const router = express.Router();

// Declared before /:userId so "me" is not captured as a userId. Any
// authenticated role; scoped to the caller's own account in the controller.
router.put('/me/password', requireAuth, changeOwnPassword);

// Admin-only directory, powers Deactivate User's name search.
router.get('/', requireAuth, requireRole('Admin'), getAllUsers);

router.delete('/:userId', requireAuth, requireRole('Admin'), deactivateUser);
router.post('/:userId/reactivate', requireAuth, requireRole('Admin'), reactivateUser);

module.exports = router;
