const bcrypt = require('bcrypt');
const { withRole } = require('../db');
const { issueToken, JWT_EXPIRES_IN } = require('../auth/tokens');

const INVALID_CREDENTIALS = 'Invalid username or password.';
const ACCOUNT_DEACTIVATED = 'This account has been deactivated.';

async function login(req, res, next) {
  try {
    const { username, password } = req.body ?? {};

    if (typeof username !== 'string' || typeof password !== 'string' || !username || !password) {
      return res.status(400).json({ error: 'username and password are required.' });
    }

    // Login runs before the user's role is known, so it reads under student_role
    // — the least privileged of the three, and enough since it holds SELECT on SLMS.*
    const rows = await withRole('student_role', async (conn) => {
      const [result] = await conn.execute(
        `SELECT u.UserID, u.Username, u.PasswordHash, u.RoleID, u.IsActive, r.RoleName
           FROM APP_USER u
           JOIN User_Role r ON u.RoleID = r.RoleID
          WHERE u.Username = :username`,
        { username }
      );
      return result;
    });

    const user = rows[0];

    // Checked before the password so a deactivated account is rejected the
    // same way whether the password given was right or wrong.
    if (user && !user.IsActive) {
      return res.status(403).json({ error: ACCOUNT_DEACTIVATED });
    }

    // Compare against a dummy hash when the user is absent so a missing account
    // and a wrong password take the same time to answer.
    const hash = user ? user.PasswordHash : DUMMY_HASH;
    const passwordMatches = await bcrypt.compare(password, hash);

    if (!user || !passwordMatches) {
      return res.status(401).json({ error: INVALID_CREDENTIALS });
    }

    return res.json({
      token: issueToken(user),
      expiresIn: JWT_EXPIRES_IN,
      user: {
        userId: user.UserID,
        username: user.Username,
        roleId: user.RoleID,
        roleName: user.RoleName,
      },
    });
  } catch (err) {
    return next(err);
  }
}

// Lets a client confirm a token is still valid and see who it belongs to.
function me(req, res) {
  const { userId, username, roleId, roleName } = req.user;
  return res.json({ userId, username, roleId, roleName });
}

// bcrypt hash of a value no password will match; only its cost matters.
const DUMMY_HASH = '$2b$10$7BJaq4zVgygNoV3Y8aMMyOVl5g/ms0nYhHG.WfLxMIGfJS2JO0Se6';

module.exports = { login, me };
