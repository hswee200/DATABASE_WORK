import { apiFetch } from './client';

// One function per backend route (see slms-backend/README.md). Mirrors the
// actual routes, not the shorthand from the frontend brief - enrollment in
// particular is POST /api/students/:studentId/enrollments, not
// /api/enrollments.

export function login(username, password) {
  return apiFetch('/api/auth/login', { method: 'POST', body: { username, password }, skipAuth: true });
}

export function getMe() {
  return apiFetch('/api/auth/me');
}

export function getTranscript(studentId) {
  return apiFetch(`/api/students/${encodeURIComponent(studentId)}/transcript`);
}

export function getStudentTimetable(studentId) {
  return apiFetch(`/api/students/${encodeURIComponent(studentId)}/timetable`);
}

export function getAttendance(studentId) {
  return apiFetch(`/api/students/${encodeURIComponent(studentId)}/attendance`);
}

export function getAssessments(studentId) {
  return apiFetch(`/api/students/${encodeURIComponent(studentId)}/assessments`);
}

export function getLecturerTimetable(lecturerId) {
  return apiFetch(`/api/lecturers/${encodeURIComponent(lecturerId)}/timetable`);
}

export function getLecturerLoad(lecturerId) {
  return apiFetch(`/api/lecturers/${encodeURIComponent(lecturerId)}/load`);
}

export function getAllLecturerLoad() {
  return apiFetch('/api/lecturers/load');
}

export function getCourseRoster(courseId) {
  return apiFetch(`/api/courses/${encodeURIComponent(courseId)}/roster`);
}

export function recordGrade(submissionId, score) {
  return apiFetch(`/api/submissions/${encodeURIComponent(submissionId)}/grade`, {
    method: 'PUT',
    body: { score },
  });
}

export function createStudent(payload) {
  return apiFetch('/api/students', { method: 'POST', body: payload });
}

export function createLecturer(payload) {
  return apiFetch('/api/lecturers', { method: 'POST', body: payload });
}

export function createAdmin(payload) {
  return apiFetch('/api/admins', { method: 'POST', body: payload });
}

export function deactivateUser(userId) {
  return apiFetch(`/api/users/${encodeURIComponent(userId)}`, { method: 'DELETE' });
}

export function reactivateUser(userId) {
  return apiFetch(`/api/users/${encodeURIComponent(userId)}/reactivate`, { method: 'POST' });
}

export function changeOwnPassword(newPassword) {
  return apiFetch('/api/users/me/password', { method: 'PUT', body: { newPassword } });
}

export function unenrollStudent(studentId, courseId) {
  return apiFetch(
    `/api/students/${encodeURIComponent(studentId)}/enrollments/${encodeURIComponent(courseId)}`,
    { method: 'DELETE' }
  );
}

export function submitAssessment(assessmentId) {
  return apiFetch('/api/submissions/submit', {
    method: 'POST',
    body: { assessmentId },
  });
}

export function resubmitAssessment(assessmentId) {
  return apiFetch('/api/submissions/resubmit', {
    method: 'POST',
    body: { assessmentId },
  });
}

export function getUngradedSubmissions() {
  return apiFetch('/api/submissions/ungraded');
}

export function deleteSubmission(submissionId) {
  return apiFetch(`/api/submissions/${encodeURIComponent(submissionId)}`, { method: 'DELETE' });
}

export function deleteAttendance(attendanceId) {
  return apiFetch(`/api/attendance/${encodeURIComponent(attendanceId)}`, { method: 'DELETE' });
}

export function updateAssessment(assessmentId, dueDate, maxScore) {
  return apiFetch(`/api/assessments/${encodeURIComponent(assessmentId)}`, {
    method: 'PUT',
    body: { dueDate, maxScore },
  });
}

export function updateAttendanceStatus(attendanceId, status) {
  return apiFetch(`/api/attendance/${encodeURIComponent(attendanceId)}/status`, {
    method: 'PUT',
    body: { status },
  });
}

export function reassignCourseLecturer(courseId, lecturerId) {
  return apiFetch(`/api/courses/${encodeURIComponent(courseId)}/lecturer`, {
    method: 'PUT',
    body: { lecturerId },
  });
}

export function updateTimetable(timetableId, payload) {
  return apiFetch(`/api/timetable/${encodeURIComponent(timetableId)}`, {
    method: 'PUT',
    body: payload,
  });
}

export function getAllCourses() {
  return apiFetch('/api/courses');
}

export function getCourseAssessments(courseId) {
  return apiFetch(`/api/courses/${encodeURIComponent(courseId)}/assessments`);
}

export function createAssessment(courseId, payload) {
  return apiFetch(`/api/courses/${encodeURIComponent(courseId)}/assessments`, {
    method: 'POST',
    body: payload,
  });
}

export function getCourseGrades(courseId) {
  return apiFetch(`/api/courses/${encodeURIComponent(courseId)}/grades`);
}

export function markAttendance(payload) {
  return apiFetch('/api/attendance', { method: 'POST', body: payload });
}

export function getBelowClassAverage(studentId) {
  return apiFetch(`/api/students/${encodeURIComponent(studentId)}/below-average`);
}

export function getUpcomingDeadlines(studentId) {
  return apiFetch(`/api/students/${encodeURIComponent(studentId)}/upcoming-deadlines`);
}

export function getLecturerReports(lecturerId) {
  return apiFetch(`/api/lecturers/${encodeURIComponent(lecturerId)}/reports`);
}

export function getAdminReports() {
  return apiFetch('/api/reports');
}

export function getAllStudents() {
  return apiFetch('/api/students');
}

export function getAllLecturers() {
  return apiFetch('/api/lecturers');
}

export function getAllUsers() {
  return apiFetch('/api/users');
}

export function getStudentAttendanceRecords(studentId, courseId) {
  const qs = courseId ? `?courseId=${encodeURIComponent(courseId)}` : '';
  return apiFetch(`/api/students/${encodeURIComponent(studentId)}/attendance-records${qs}`);
}
