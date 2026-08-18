require('dotenv').config();
const mysql = require('mysql2/promise');

const DB_NAME = process.env.DB_NAME;

if (!/^[A-Za-z0-9_]+$/.test(DB_NAME ?? '')) {
  throw new Error('DB_NAME must be a plain identifier; it is interpolated into USE.');
}

// No `database` here on purpose: the app account has no privileges until a role
// is activated, so selecting a schema at connect time is refused. Each request
// activates its role first, then issues USE.
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  waitForConnections: true,
  connectionLimit: 10,
  namedPlaceholders: true,
  // DATE columns are calendar dates with no time or zone. Left as JS Dates they
  // serialize to "2026-08-13T00:00:00.000Z" and can read as the previous day for
  // clients behind UTC. TIMESTAMP is a real instant, so it keeps Date handling.
  dateStrings: ['DATE'],
});

const ROLE_BY_ID = {
  1: 'admin_role',
  2: 'lecturer_role',
  3: 'student_role',
};

// SET ROLE takes an identifier, which cannot be a bound parameter, so the name
// is resolved through this map and never built from caller input.
const VALID_ROLES = new Set(Object.values(ROLE_BY_ID));

function roleForRoleId(roleId) {
  const role = ROLE_BY_ID[roleId];
  if (!role) throw new Error(`No database role mapped for RoleID ${roleId}`);
  return role;
}

// The app account connects with no role active (SET DEFAULT ROLE NONE), so every
// query must run inside here. Pooled connections are reused, so the role is set
// on each acquisition and cleared on release rather than assumed.
async function withRole(roleName, fn) {
  if (!VALID_ROLES.has(roleName)) {
    throw new Error(`Unknown database role: ${roleName}`);
  }

  const conn = await pool.getConnection();
  try {
    await conn.query(`SET ROLE ${roleName}`);
    await conn.query(`USE \`${DB_NAME}\``);
    return await fn(conn);
  } finally {
    try {
      await conn.query('SET ROLE NONE');
      conn.release();
    } catch {
      // A connection we cannot reset must not rejoin the pool carrying a role.
      conn.destroy();
    }
  }
}

module.exports = { pool, withRole, roleForRoleId, ROLE_BY_ID };
