const { verifyToken } = require('../auth/tokens');
const { roleForRoleId } = require('../db');

// Populates req.user from the bearer token. Everything downstream reads identity
// from here, never from the request body or query string.
function requireAuth(req, res, next) {
  const header = req.get('authorization') || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header.' });
  }

  let claims;
  try {
    claims = verifyToken(token);
  } catch (err) {
    const expired = err.name === 'TokenExpiredError';
    return res.status(401).json({ error: expired ? 'Token expired.' : 'Invalid token.' });
  }

  let dbRole;
  try {
    dbRole = roleForRoleId(claims.roleId);
  } catch {
    return res.status(403).json({ error: 'Token carries an unrecognized role.' });
  }

  req.user = {
    userId: claims.sub,
    username: claims.username,
    roleId: claims.roleId,
    roleName: claims.roleName,
    dbRole,
  };

  return next();
}

// Route guard for endpoints limited to specific application roles.
function requireRole(...allowedRoleNames) {
  return (req, res, next) => {
    if (!req.user || !allowedRoleNames.includes(req.user.roleName)) {
      return res.status(403).json({ error: 'Not permitted for this role.' });
    }
    return next();
  };
}

module.exports = { requireAuth, requireRole };
