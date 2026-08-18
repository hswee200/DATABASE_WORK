require('dotenv').config();
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '8h';

// Fail at startup rather than per request: a missing secret would otherwise make
// every token trivially forgeable, and a placeholder value is no better.
if (!JWT_SECRET || JWT_SECRET === 'replace-me' || JWT_SECRET.length < 32) {
  throw new Error(
    'JWT_SECRET must be set in .env to a random value of at least 32 characters. ' +
      'Generate one with: node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'hex\'))"'
  );
}

// RoleID is carried in the token so authorization never re-reads it from a
// client-supplied field. `sub` is the APP_USER.UserID.
function issueToken(user) {
  return jwt.sign(
    {
      sub: user.UserID,
      username: user.Username,
      roleId: user.RoleID,
      roleName: user.RoleName,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN, algorithm: 'HS256' }
  );
}

function verifyToken(token) {
  // Pinning the algorithm blocks "alg": "none" and HS/RS confusion attacks.
  return jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
}

module.exports = { issueToken, verifyToken, JWT_EXPIRES_IN };
