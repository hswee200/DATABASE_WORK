// Who may read whose records. Kept in one place so every student- or
// lecturer-scoped endpoint applies the same rule instead of re-deriving it.
//
// All comparisons use `username`, not `userId`: the token's `sub` is the
// APP_USER.UserID (U001), while StudentID/LecturerID is the Username (S001,
// L001). The schema guarantees Username equals the person's own ID.

function canReadStudent(user, studentId) {
  if (user.roleName === 'Admin') return true;
  if (user.roleName === 'Student') return user.username === studentId;
  // Lecturers are refused until the course-ownership check lands with grading;
  // a lecturer has no blanket right to a student's records.
  return false;
}

function canReadLecturer(user, lecturerId) {
  if (user.roleName === 'Admin') return true;
  if (user.roleName === 'Lecturer') return user.username === lecturerId;
  return false;
}

// Whether this user may modify course content that requires a lecturer's
// subject-matter judgment - grading a submission, editing an assessment's due
// date/max score, or correcting an attendance status - given the lecturer who
// owns the underlying course.
//
// Deliberately Lecturer-only, with no Admin bypass. Admin (the registrar
// function) manages accounts, enrolment, and scheduling; it does not grade
// papers or take attendance, the same way a real registrar and a real
// instructor are different jobs. `admin_role` still holds ALL PRIVILEGES at
// the database level for DBA-style emergency recovery - that grant is
// intentionally untouched - but this function is what keeps that access from
// leaking into the application layer as an academic-judgment shortcut.
//
// This is also the row-level restriction the database cannot express on its
// own: GRANT works at table level, so lecturer_role can UPDATE any course's
// rows, and these procedures run as DEFINER=root and would happily act on
// another lecturer's course. This check is the only thing enforcing ownership
// — there is no backstop underneath.
function canModifyCourseContent(user, owningLecturerId) {
  if (user.roleName === 'Lecturer') return user.username === owningLecturerId;
  return false;
}

// Whether this user may READ course-wide data such as a roster.
//
// Read access only — nothing here grants the right to modify a course or its
// enrolments. Those remain Admin-only, enforced at the route with requireRole.
//
// `isEnrolled` must be resolved by the caller, since it needs a query; keeping
// this function pure means the rules stay readable and testable in one place.
function canReadCourse(user, owningLecturerId, isEnrolled = false) {
  if (user.roleName === 'Admin') return true;
  if (user.roleName === 'Lecturer') return user.username === owningLecturerId;
  // A student sees the roster of a class they are actually in, and no other.
  if (user.roleName === 'Student') return isEnrolled;
  return false;
}

module.exports = { canReadStudent, canReadLecturer, canModifyCourseContent, canReadCourse };
