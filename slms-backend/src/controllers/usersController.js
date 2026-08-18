const bcrypt = require('bcrypt');
const { withRole } = require('../db');

const BCRYPT_ROUNDS = 10;
const MIN_PASSWORD_LENGTH = 8;

// Matches the schema's column widths so oversized input returns a clean 400
// rather than a truncation error or a 500 from the driver.
const LIMITS = { id: 20, email: 100, name: 30 };

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

function validate(body) {
  const errors = [];
  const { email, password, firstName, lastName, dateOfBirth } = body;

  const required = (value, name, max) => {
    if (typeof value !== 'string' || value.trim() === '') {
      errors.push(`${name} is required.`);
    } else if (value.length > max) {
      errors.push(`${name} must be at most ${max} characters.`);
    }
  };

  required(email, 'email', LIMITS.email);
  required(firstName, 'firstName', LIMITS.name);
  required(lastName, 'lastName', LIMITS.name);

  // Deliberately permissive: enough to catch a typo, not a spec-complete parser.
  if (typeof email === 'string' && email.trim() !== '' && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    errors.push('email must be a valid address.');
  }

  if (typeof password !== 'string' || password.length < MIN_PASSWORD_LENGTH) {
    errors.push(`password is required and must be at least ${MIN_PASSWORD_LENGTH} characters.`);
  }

  // Optional: DateOfBirth is nullable in the schema.
  if (dateOfBirth !== undefined && dateOfBirth !== null) {
    if (typeof dateOfBirth !== 'string' || !ISO_DATE.test(dateOfBirth)) {
      errors.push('dateOfBirth must be in YYYY-MM-DD format.');
    } else if (Number.isNaN(Date.parse(dateOfBirth))) {
      errors.push('dateOfBirth is not a valid date.');
    }
  }

  return errors;
}

// The three sp_create_* procedures share a signature, so one implementation
// covers all three roles and the validation cannot drift between them.
// UserID and the role-specific ID (StudentID/LecturerID/AdminID) are never
// supplied by the caller - the procedure generates both internally (same
// MAX(...)+1 pattern sp_enroll_student uses for EnrollmentID) and returns
// them via a trailing SELECT, since nobody should have to invent or
// remember "the next free ID."
function makeCreateUser({ procedure, idField, idColumn, roleLabel }) {
  return async function createUser(req, res, next) {
    try {
      const body = req.body || {};
      const errors = validate(body);
      if (errors.length > 0) {
        return res.status(400).json({ error: errors.join(' '), details: errors });
      }

      const { email, password, firstName, lastName } = body;
      const dateOfBirth = body.dateOfBirth ?? null;

      // Hashed here so plaintext never reaches a SQL statement, the query log,
      // or the procedure. The procedure stores whatever it is given.
      const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);

      // Wraps the APP_USER + profile inserts in one transaction and rolls back
      // on failure, so a login row without a profile row cannot occur. Never
      // replace this with two separate inserts. CALL returns a nested result:
      // [rows, ResultSetHeader] - rows here is the procedure's trailing SELECT.
      const [result] = await withRole(req.user.dbRole, (conn) =>
        conn.query(`CALL ${procedure}(?, ?, ?, ?, ?)`, [
          email,
          passwordHash,
          firstName,
          lastName,
          dateOfBirth,
        ])
      );
      const generated = result[0][0];
      const profileId = generated[idColumn];

      return res.status(201).json({
        userId: generated.UserID,
        [idField]: profileId,
        username: profileId,
        email,
        firstName,
        lastName,
        dateOfBirth,
        role: roleLabel,
      });
    } catch (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        // Email is the only caller-supplied field with a uniqueness
        // constraint now that both IDs are generated - a collision here is
        // always the email.
        return res.status(409).json({ error: 'A user with that email already exists.' });
      }
      return next(err);
    }
  };
}

async function deactivateUser(req, res, next) {
  try {
    const { userId } = req.params;

    // Looked up before deactivating so the response can name who was
    // deactivated instead of just echoing back the ID the admin typed.
    const context = await withRole(req.user.dbRole, async (conn) => {
      const [rows] = await conn.execute(
        `SELECT u.Username, r.RoleName
           FROM APP_USER u
           JOIN User_Role r ON u.RoleID = r.RoleID
          WHERE u.UserID = ?`,
        [userId]
      );
      await conn.query('CALL sp_deactivate_user(?)', [userId]);
      return rows[0];
    });

    return res.json({
      userId,
      deactivated: true,
      username: context?.Username ?? null,
      roleName: context?.RoleName ?? null,
    });
  } catch (err) {
    // sp_deactivate_user raises only one 45000 here: unknown or already-inactive user.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

async function reactivateUser(req, res, next) {
  try {
    const { userId } = req.params;

    // Same lookup-before-mutate shape as deactivateUser, so the response can
    // name who was reactivated instead of just echoing back the ID.
    const context = await withRole(req.user.dbRole, async (conn) => {
      const [rows] = await conn.execute(
        `SELECT u.Username, r.RoleName
           FROM APP_USER u
           JOIN User_Role r ON u.RoleID = r.RoleID
          WHERE u.UserID = ?`,
        [userId]
      );
      await conn.query('CALL sp_reactivate_user(?)', [userId]);
      return rows[0];
    });

    return res.json({
      userId,
      reactivated: true,
      username: context?.Username ?? null,
      roleName: context?.RoleName ?? null,
    });
  } catch (err) {
    // sp_reactivate_user raises only one 45000 here: unknown or already-active user.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

// Any authenticated role, strictly limited to the caller's own account: the
// UserID comes from the verified token, never from the request body or
// params, so there is no ownership check to get wrong - a user simply cannot
// name another account.
async function changeOwnPassword(req, res, next) {
  try {
    const { newPassword } = req.body || {};

    if (typeof newPassword !== 'string' || newPassword.length < MIN_PASSWORD_LENGTH) {
      return res
        .status(400)
        .json({ error: `newPassword is required and must be at least ${MIN_PASSWORD_LENGTH} characters.` });
    }

    // Hashed here so plaintext never reaches a SQL statement, the query log,
    // or the procedure - same as account creation.
    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

    await withRole(req.user.dbRole, (conn) =>
      conn.query('CALL sp_change_password(?, ?)', [req.user.userId, passwordHash])
    );

    return res.status(204).send();
  } catch (err) {
    // sp_change_password raises only one 45000: unknown or inactive user -
    // which should not happen for a token that just passed requireAuth, but
    // handled defensively rather than surfacing as a generic 500.
    if (err.sqlState === '45000') {
      return res.status(404).json({ error: err.sqlMessage });
    }
    return next(err);
  }
}

// Cross-role directory for admin search-by-name: a UserID could belong to
// any of the three profile tables, so this joins whichever one matches
// rather than making the caller already know which role they're looking
// for. Admin-only, used to power Deactivate User's name search.
async function getAllUsers(req, res, next) {
  try {
    const rows = await withRole(req.user.dbRole, async (conn) => {
      const [result] = await conn.execute(
        `SELECT u.UserID, u.Username, r.RoleName, u.IsActive,
                COALESCE(st.F_Name, l.F_Name, a.F_Name) AS F_Name,
                COALESCE(st.L_Name, l.L_Name, a.L_Name) AS L_Name
           FROM APP_USER u
           JOIN User_Role r ON u.RoleID = r.RoleID
           LEFT JOIN STUDENT st ON st.UserID = u.UserID
           LEFT JOIN Lecturer l ON l.UserID = u.UserID
           LEFT JOIN Admin_USER a ON a.UserID = u.UserID
          ORDER BY F_Name, L_Name`
      );
      return result;
    });

    return res.json({
      users: rows.map((row) => ({
        userId: row.UserID,
        username: row.Username,
        roleName: row.RoleName,
        isActive: Boolean(row.IsActive),
        firstName: row.F_Name,
        lastName: row.L_Name,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createStudent: makeCreateUser({
    procedure: 'sp_create_student',
    idField: 'studentId',
    idColumn: 'StudentID',
    roleLabel: 'Student',
  }),
  createLecturer: makeCreateUser({
    procedure: 'sp_create_lecturer',
    idField: 'lecturerId',
    idColumn: 'LecturerID',
    roleLabel: 'Lecturer',
  }),
  createAdmin: makeCreateUser({
    procedure: 'sp_create_admin',
    idField: 'adminId',
    idColumn: 'AdminID',
    roleLabel: 'Admin',
  }),
  deactivateUser,
  reactivateUser,
  changeOwnPassword,
  getAllUsers,
};
