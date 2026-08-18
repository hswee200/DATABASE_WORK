-- SLMS backend: dedicated application database account.
-- Engine note: this server is MariaDB 12.2, not MySQL. Role syntax differs from
-- MySQL in two places, both reflected below:
--   * SET DEFAULT ROLE uses FOR (MariaDB), not TO (MySQL)
--   * MariaDB grants roles one per statement
-- Must run as root@localhost: only root holds ADMIN OPTION on these three roles,
-- so no other account can grant them. Re-runnable.

CREATE USER IF NOT EXISTS 'slms_application_user'@'localhost'
  IDENTIFIED BY '0Dfh6v1EJA-LGy80ixBfegWgdid4alFE';

-- The backend server acts as whichever role matches the logged-in person,
-- so the single app account must hold all three.
GRANT admin_role    TO 'slms_application_user'@'localhost';
GRANT lecturer_role TO 'slms_application_user'@'localhost';
GRANT student_role  TO 'slms_application_user'@'localhost';

-- No role active on connect: a code path that forgets SET ROLE fails with a
-- permissions error instead of silently running with admin rights.
SET DEFAULT ROLE NONE FOR 'slms_application_user'@'localhost';

-- The account needs to reach the schema itself; all table-level rights come
-- from whichever role is activated per request.
GRANT USAGE ON SLMS.* TO 'slms_application_user'@'localhost';

FLUSH PRIVILEGES;
