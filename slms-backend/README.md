# SLMS Backend

Node.js + Express API over the SLMS database (CS254 group project, Topic 9).

The database is the source of truth — schema, views, functions, procedures and
triggers were designed and tested first, and this backend calls into them rather
than reimplementing their logic. See `SLMS_Design_Context.md` in the parent
directory for the reasoning behind the schema.

**Engine:** MariaDB (not MySQL). The design document says MySQL, but the actual
instance is MariaDB, and the role syntax differs. Anything you write from that
document should be checked against MariaDB syntax.

---

## Setup

**Requirements:** Node 18+, a running MariaDB with the `SLMS` schema loaded.

```bash
npm install
cp .env.example .env     # then fill in the values below
npm start                # or: npm run dev  (restarts on file changes)
```

### Environment variables

All live in `.env`, which is gitignored. `.env.example` documents the shape.

| Variable | Purpose |
|---|---|
| `PORT` | HTTP port (default 3000) |
| `DB_HOST` / `DB_PORT` | MariaDB address, e.g. `127.0.0.1` / `3306` |
| `DB_NAME` | `SLMS` |
| `DB_USER` | `slms_application_user` — **not root** |
| `DB_PASSWORD` | That account's password |
| `JWT_SECRET` | Signing key for auth tokens |
| `JWT_EXPIRES_IN` | Token lifetime, default `8h` |

`JWT_SECRET` is effectively a master key: anyone holding it can mint a token for
any user, including an admin. Generate a fresh one per environment and never
commit it:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

The server refuses to start if `JWT_SECRET` is missing, still `replace-me`, or
under 32 characters — otherwise tokens would be signed with `undefined` and
every one of them forgeable, with nothing appearing broken.

### Database setup

Run in order, as root. Each is idempotent enough to re-run safely.

| Script | What it does |
|---|---|
| `sql/01_app_user_setup.sql` | Creates `slms_application_user`, grants all three DB roles, sets `DEFAULT ROLE NONE` |
| `sql/02_seed_password_hashes.sql` | Replaces placeholder hashes so seed accounts can log in (`Password123!`) |
| `sql/03_grant_execute.sql` | Grants `EXECUTE` per-procedure — the schema granted `SELECT` but never `EXECUTE` |
| `sql/04_fix_negative_score.sql` | Recreates `sp_record_grade` to reject negative scores |

```bash
mysql -u root -p < sql/01_app_user_setup.sql
```

> `sql/04` uses `DROP PROCEDURE` + `CREATE`, and dropping a routine also drops
> its privileges — so it re-grants `EXECUTE` to `lecturer_role` at the end. If
> you ever recreate a procedure by hand, re-grant it or lecturers will start
> getting 500s.

---

## Architecture: two layers of roles

The schema deliberately keeps two separate permission systems. This backend
uses both, and they must not be merged.

**Application roles** — `APP_USER.RoleID` → `User_Role.RoleName` (Admin,
Lecturer, Student). Decides what a logged-in person may do. Carried in the JWT
and checked by `requireRole(...)` and `src/auth/access.js`.

**Database roles** — `admin_role`, `lecturer_role`, `student_role`. Restrict
what the SQL connection itself may do. End users never get MariaDB credentials;
only the app server connects, as `slms_application_user`.

That account has `DEFAULT ROLE NONE`, so it holds **no privileges on connect** —
it cannot even select the schema. Every request activates the role matching the
caller before running anything:

```
requireAuth reads RoleID from the token  →  withRole('student_role', fn)
   →  SET ROLE student_role  →  USE SLMS  →  query  →  connection released
```

`SET ROLE` is re-issued per request because pooled connections are reused. If a
code path ever forgets it, the query fails outright rather than silently running
with more privilege than intended. That is why the pool config has no `database`
option — selecting a schema at connect time would be refused.

Full reasoning: `SLMS_Design_Context.md`, section 2.

---

## Known limitation: procedures bypass the role layer

Every stored procedure is `SQL SECURITY DEFINER` with `DEFINER=root@localhost`,
so its body runs with **root privileges regardless of which role the connection
activated**. The role layer protects direct queries only.

`GRANT` is also table-level, so `lecturer_role` can update *any* row of
`SUBMISSION` — it cannot express "only rows for courses this lecturer teaches".

Together these mean ownership rules are enforced **only** in application code,
in `src/auth/access.js`. This was verified, not assumed — calling
`sp_record_grade` directly under `lecturer_role` against another lecturer's
submission **succeeds** at the database level.

So `canGradeSubmission()` is the only thing preventing a lecturer from grading a
colleague's students. Remove it and nothing else fails; cross-lecturer grading
just quietly becomes possible. Any new endpoint touching student- or
course-scoped data must call into `src/auth/access.js` rather than rolling its
own check.

---

## Endpoints

All except login require `Authorization: Bearer <token>`.

Errors are `{ "error": "..." }`. Common statuses: `400` invalid input, `401`
missing/invalid/expired token, `403` not permitted, `404` unknown ID, `409`
conflicts with existing state, `500` unexpected (details go to the server log,
never the response).

### `POST /api/auth/login`

Public. Body `{ "username": "S001", "password": "Password123!" }`.

`Username` is always the person's own ID — `S001`, `L001`, `A001`.

```json
{ "token": "eyJhbGci...", "expiresIn": "8h",
  "user": { "userId": "U001", "username": "S001", "roleId": 3, "roleName": "Student" } }
```

Unknown username and wrong password both return the same 401, so neither can be
used to discover which accounts exist.

### `GET /api/auth/me`

Any role. Confirms a token is still valid and returns its identity.

### `GET /api/students/:studentId/transcript`

Student (own only) or Admin (any). Lecturers are refused. Calls
`sp_generate_transcript`.

```json
{ "studentId": "S001",
  "transcript": [ { "semesterName": "Semester 2", "academicYear": "2027/2028",
                    "courseId": "C001", "courseName": "Artificial Intelligence",
                    "finalGradePercent": 92 } ] }
```

A student with no graded submissions returns `200` and an empty array — that is
a valid state, not an error. `finalGradePercent` is a number; the driver returns
`DECIMAL` as a string, so it is converted.

### `GET /api/students/:studentId/timetable`

Student (own only) or Admin (any). Reads `VW_STUDENT_TIMETABLE`.

```json
{ "studentId": "S001",
  "timetable": [ { "courseCode": "CS254", "courseName": "Artificial Intelligence",
                   "dayOfWeek": "Monday", "startTime": "10:00:00",
                   "endTime": "12:00:00", "room": "Room 204" } ] }
```

### `GET /api/lecturers/:lecturerId/timetable`

Lecturer (own only) or Admin (any). Reads `VW_LECTURER_TIMETABLE`, which also
carries `semesterName` and `academicYear` — the student view has no semester
columns, so the two are not symmetric.

Both timetables are sorted Monday→Sunday then by start time. The views have no
`ORDER BY`, and sorting `DayOfWeek` as text would put Friday first.

### `POST /api/students/:studentId/enrollments`

**Admin only.** Body `{ "courseId": "C005" }`. Calls `sp_enroll_student`, which
generates the `EnrollmentID` itself. Returns `201`.

```json
{ "enrollmentId": "E021", "studentId": "S001",
  "courseId": "C005", "enrollmentDate": "2026-08-13" }
```

Duplicate enrolment returns `409` — a conflict with existing state, not bad
input.

### `PUT /api/submissions/:submissionId/grade`

Lecturer (own courses only) or Admin (any). Students refused. Body
`{ "score": 95 }`. Calls `sp_record_grade`.

```json
{ "submissionId": "SUB001", "courseId": "C001",
  "previousScore": 92, "score": 95, "maxScore": 100 }
```

Ownership is resolved through `SUBMISSION → ASSESSMENT → COURSE → LecturerID`
and checked **before** the call, since the procedure itself would not stop it.

Scores above `MaxScore` and negative scores are both rejected with `400`. Both
rules are enforced twice on purpose — in the database (`sp_record_grade`) and in
the backend — so the database stays the authority and the app is a second layer.

`trg_log_score_change` writes to `SUBMISSION_AUDIT_LOG` automatically on every
successful change. The backend does nothing to trigger this.

### `GET /api/courses/:courseId/roster`

Read-only for everyone who can see it:

| Role | Access |
|---|---|
| Student | Rosters of courses they are **enrolled in**, and no others |
| Lecturer | Rosters of courses they **teach** |
| Admin | Any course |

Nothing here permits modifying a course or its enrolments — enrolment stays
Admin-only via `POST /api/students/:id/enrollments`.

The student case needs an `ENROLLMENT` lookup, which is why access is decided in
the controller rather than by `requireRole`: role alone cannot express "is in
this particular class".

Reads `VW_COURSE_ROSTER`, but takes the course and lecturer details from
`COURSE`/`Lecturer`, since the view joins `ENROLLMENT` and returns nothing at
all for a course with no students yet.

```json
{ "courseId": "C001", "courseCode": "CS254", "courseName": "Artificial Intelligence",
  "lecturer": { "lecturerId": "L001", "firstName": "Kofi", "lastName": "Boateng" },
  "enrolledCount": 1,
  "students": [ { "studentId": "S001", "firstName": "Ama", "lastName": "Owusu",
                  "enrollmentDate": "2026-08-13" } ] }
```

### `GET /api/students/:studentId/attendance`

Student (own only) or Admin (any). Reads `VW_ATTENDANCE_SUMMARY`, one row per
course.

```json
{ "studentId": "S001",
  "attendance": [ { "courseId": "C001", "courseName": "Artificial Intelligence",
                    "timesPresent": 2, "timesAbsent": 0, "timesLate": 0,
                    "totalSessions": 2, "attendanceRate": 100 } ] }
```

Note `attendanceRate` counts only `Present` — `Late` does not count toward it,
matching the view's definition.

### `GET /api/students/:studentId/assessments`

Student (own only) or Admin (any). Reads `VW_ASSESSMENT_STATUS`, sorted by due
date so an "upcoming work" list needs no client-side sort.

```json
{ "studentId": "S001",
  "assessments": [ { "assessmentId": "AS001", "assessmentName": "Search Algorithms Assignment",
                     "courseId": "C001", "dueDate": "2026-09-20",
                     "submissionId": "SUB001", "status": "Submitted" } ] }
```

`status` is computed by the view: `Submitted`, `Past-Due`, or `Upcoming`.
`submissionId` is `null` when nothing has been submitted.

### `GET /api/lecturers/:lecturerId/load`

Lecturer (own only) or Admin (any). Reads `VW_LECTURER_LOAD`.

```json
{ "lecturerId": "L001", "firstName": "Kofi", "lastName": "Boateng",
  "numCourses": 1, "numStudents": 1 }
```

The view `LEFT JOIN`s from `Lecturer`, so a lecturer with no courses still
appears with zeroes. A missing row therefore means the lecturer does not exist,
which is what the `404` relies on.

### `GET /api/lecturers/load`

**Admin only.** All lecturers at once, busiest first — a staffing overview.

```json
{ "lecturers": [ { "lecturerId": "L001", "firstName": "Kofi", "lastName": "Boateng",
                   "numCourses": 1, "numStudents": 1 } ] }
```

> Declared **before** `/:lecturerId/...` in `src/routes/lecturers.js`. Express
> matches in definition order, so a later declaration would work here but the
> ordering is what keeps `load` from being read as a lecturerId in future
> single-segment routes. The smoke test covers it either way.

### Creating users

`POST /api/students` · `POST /api/lecturers` · `POST /api/admins`

**Admin only** — creating an admin grants full application privileges, so an
existing admin must do it.

```json
{ "userId": "U061", "studentId": "S021",
  "email": "new.student@lms.edu", "password": "TestPass123!",
  "firstName": "Ama", "lastName": "Mensah", "dateOfBirth": "2004-03-15" }
```

The ID field is `studentId`, `lecturerId`, or `adminId` to match the endpoint.
`dateOfBirth` is optional (`DATE` is nullable). IDs are supplied explicitly
rather than generated — the schema uses string IDs like `S021`, and
auto-generating them would repeat the `MAX(...)+1` concurrency weakness already
noted in `sp_enroll_student`.

Response `201` — never the password or its hash:

```json
{ "userId": "U061", "studentId": "S021", "username": "S021",
  "email": "new.student@lms.edu", "firstName": "Ama", "lastName": "Mensah",
  "dateOfBirth": "2004-03-15", "role": "Student" }
```

`username` is always the person's own ID; the procedure sets it, the backend
does not choose it.

**The password is bcrypt-hashed (cost 10) before it reaches SQL**, so plaintext
never appears in a statement, the query log, or the procedure. Minimum 8
characters.

Each endpoint calls `sp_create_student` / `sp_create_lecturer` /
`sp_create_admin`, which wrap the `APP_USER` and profile inserts in a single
transaction. Do not replace these with two separate inserts — the transaction is
what prevents a login row existing without a profile row. Verified: a create
that fails on a duplicate email leaves **no** orphan `APP_USER` row.

Validation returns `400` with a `details` array listing every problem at once.
Duplicate `userId`, ID, or email returns `409`; the message names the field but
never echoes the submitted value back.

No new grants were needed — `admin_role` already holds `EXECUTE` on all three
procedures through `GRANT ALL PRIVILEGES`.

---

## Running the tests

`scripts/smoke-test.sh` reproduces the full verification suite.

```bash
npm start                    # in one terminal
./scripts/smoke-test.sh      # in another
```

69 checks, **read-only** — every case is a rejection or a read, so the database
is unchanged. Expected output ends with `69 passed, 0 failed`.

```
GRADING (rejections only - no data written)
  PASS  L001 grades L002's course                      403
  PASS  student blocked                                403
  PASS  score above MaxScore                           400
  PASS  negative score                                 400
```

### Write tests

```bash
./scripts/smoke-test.sh --write
```

Adds 8 checks that **modify the database**: enrols S001 in C006, grades SUB001
to 95 then back to 92, and creates users `S990` / `L990` / `A990` (also
confirming a newly created user can log in). Re-running gives `409` instead of
`201` for the enrolment and the user creates, and the two grade changes leave
rows in `SUBMISSION_AUDIT_LOG` even though the score ends where it started — the
trigger records every change.

Clean up in this order; the profile rows reference `APP_USER`, so they must go
first:

```sql
DELETE FROM ENROLLMENT WHERE StudentID = 'S001' AND CourseID = 'C006';
DELETE FROM SUBMISSION_AUDIT_LOG WHERE SubmissionID = 'SUB001' AND LogID > 1;
DELETE FROM STUDENT    WHERE StudentID  = 'S990';
DELETE FROM Lecturer   WHERE LecturerID = 'L990';
DELETE FROM Admin_USER WHERE AdminID    = 'A990';
DELETE FROM APP_USER   WHERE UserID IN ('U990','U991','U992');
```

### Verifying role isolation

To confirm the database roles still restrict correctly — for example after
changing a grant:

```bash
mysql -u slms_application_user -p -e \
  "SET ROLE student_role; USE SLMS; UPDATE ASSESSMENT SET AssessmentName=AssessmentName WHERE 1=0;"
```

Expect `ERROR 1142 ... UPDATE command denied`. If it succeeds, `student_role`
has been granted more than it should have.

---

## Layout

```
src/
  server.js                 Express app, route mounting
  db.js                     Pool + withRole() — activates a DB role per request
  constants.js              Shared SQL fragments (weekday ordering)
  auth/
    tokens.js               JWT issue/verify, startup validation of JWT_SECRET
    access.js               Ownership rules — the only enforcement of row-level access
  middleware/
    requireAuth.js          Bearer token -> req.user; requireRole() guard
    errorHandler.js         SQLSTATE 45000 -> 400; everything else -> 500
  controllers/              One per resource (students, lecturers, courses,
                            submissions, enrollments, auth)
  routes/                   One per resource
sql/                        Numbered setup scripts, run as root in order
scripts/smoke-test.sh       Full endpoint verification
```

## Coverage

All seven views and all four read/write procedures are now reachable through the
API:

| Schema object | Endpoint |
|---|---|
| `sp_generate_transcript` | `GET /api/students/:id/transcript` |
| `sp_enroll_student` | `POST /api/students/:id/enrollments` |
| `sp_record_grade` | `PUT /api/submissions/:id/grade` |
| `VW_STUDENT_TIMETABLE` | `GET /api/students/:id/timetable` |
| `VW_LECTURER_TIMETABLE` | `GET /api/lecturers/:id/timetable` |
| `VW_STUDENT_FINAL_GRADES` | via `sp_generate_transcript` |
| `VW_COURSE_ROSTER` | `GET /api/courses/:id/roster` |
| `VW_ATTENDANCE_SUMMARY` | `GET /api/students/:id/attendance` |
| `VW_ASSESSMENT_STATUS` | `GET /api/students/:id/assessments` |
| `VW_LECTURER_LOAD` | `GET /api/lecturers/:id/load`, `GET /api/lecturers/load` |
| `sp_create_student` | `POST /api/students` |
| `sp_create_lecturer` | `POST /api/lecturers` |
| `sp_create_admin` | `POST /api/admins` |

Every view and every procedure in the schema is now reachable. None of the
view-backed endpoints needed new grants — the views are plain `SELECT`s that
`student_role` and `lecturer_role` could already read.

## Not yet built

`fn_calculate_final_grade` and `fn_attendance_rate` are unused: the views compute
their own equivalents, so no endpoint needs them. If one ever does, note that
`student_role` and `lecturer_role` have **no `EXECUTE`** on functions — calling
one will need a grant in the style of `sql/03_grant_execute.sql`.

There is no endpoint for updating or deleting users, editing courses, or
recording attendance. Attendance in particular has a trigger
(`trg_prevent_duplicate_attendance`) already waiting for it.
