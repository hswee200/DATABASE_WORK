import { useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import {
  getCourseRoster,
  markAttendance,
  updateAttendanceStatus,
  getStudentAttendanceRecords,
} from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import StatusBanner from '../../../components/StatusBanner';

const STATUSES = ['Present', 'Absent', 'Late'];

function MarkAttendanceForm({ sessions, students }) {
  const [studentId, setStudentId] = useState('');
  const [timetableId, setTimetableId] = useState(sessions[0]?.timetableId ?? '');
  const [attendanceDate, setAttendanceDate] = useState('');
  const [status, setStatus] = useState(STATUSES[0]);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      // No attendanceId here - the backend generates it (same pattern as
      // sp_enroll_student).
      const data = await markAttendance({ studentId, timetableId, attendanceDate, status });
      setSuccess(`Marked ${data.studentFirstName} ${data.studentLastName} as ${data.status} on ${data.attendanceDate}.`);
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <h2 className="section-heading">Mark Attendance</h2>
      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 1rem' }}>
          <div className="field">
            <label htmlFor="markStudent">Student</label>
            <select
              id="markStudent"
              value={studentId}
              onChange={(e) => setStudentId(e.target.value)}
              required
            >
              <option value="" disabled>
                Choose…
              </option>
              {students.map((s) => (
                <option key={s.studentId} value={s.studentId}>
                  {s.firstName} {s.lastName}
                </option>
              ))}
            </select>
          </div>
          {sessions.length > 1 && (
            <div className="field">
              <label htmlFor="markSession">Session</label>
              <select
                id="markSession"
                value={timetableId}
                onChange={(e) => setTimetableId(e.target.value)}
              >
                {sessions.map((s) => (
                  <option key={s.timetableId} value={s.timetableId}>
                    {s.dayOfWeek} {s.startTime.slice(0, 5)}–{s.endTime.slice(0, 5)}
                  </option>
                ))}
              </select>
            </div>
          )}
          <div className="field">
            <label htmlFor="markDate">Date</label>
            <input
              id="markDate"
              type="date"
              value={attendanceDate}
              onChange={(e) => setAttendanceDate(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="markStatus">Status</label>
            <select id="markStatus" value={status} onChange={(e) => setStatus(e.target.value)}>
              {STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>
        </div>
        <button
          type="submit"
          className="btn-primary"
          disabled={submitting || !studentId || !timetableId || !attendanceDate}
        >
          {submitting ? 'Saving…' : 'Mark Attendance'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </div>
  );
}

// Picking which record to correct is a two-step name -> record flow rather
// than a typed AttendanceID: choose the student (same roster dropdown Mark
// Attendance uses), then choose which of their dated records for this
// course to change.
function CorrectAttendanceForm({ courseId, students }) {
  const [studentId, setStudentId] = useState('');
  const [attendanceId, setAttendanceId] = useState('');
  const [status, setStatus] = useState(STATUSES[0]);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const { data, loading: loadingRecords } = useApi(
    () => (studentId ? getStudentAttendanceRecords(studentId, courseId) : Promise.resolve(null)),
    [studentId, courseId]
  );
  const records = data?.records ?? [];

  function handleStudentChange(id) {
    setStudentId(id);
    setAttendanceId('');
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      const data = await updateAttendanceStatus(attendanceId, status);
      setSuccess(
        `${data.studentFirstName} ${data.studentLastName} (${data.courseName}) updated to ${data.status}.`
      );
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <h2 className="section-heading">Correct Attendance</h2>
      <form className="inline-form" onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="correctStudent">Student</label>
          <select
            id="correctStudent"
            value={studentId}
            onChange={(e) => handleStudentChange(e.target.value)}
            required
          >
            <option value="" disabled>
              Choose…
            </option>
            {students.map((s) => (
              <option key={s.studentId} value={s.studentId}>
                {s.firstName} {s.lastName}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="correctRecord">Record</label>
          <select
            id="correctRecord"
            value={attendanceId}
            onChange={(e) => setAttendanceId(e.target.value)}
            required
            disabled={!studentId || loadingRecords}
          >
            <option value="" disabled>
              {loadingRecords ? 'Loading…' : 'Choose…'}
            </option>
            {records.map((r) => (
              <option key={r.attendanceId} value={r.attendanceId}>
                {r.attendanceDate} — {r.status}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="correctStatus">New Status</label>
          <select id="correctStatus" value={status} onChange={(e) => setStatus(e.target.value)}>
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </div>
        <button type="submit" className="btn-primary" disabled={submitting || !attendanceId}>
          {submitting ? 'Saving…' : 'Save Changes'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </div>
  );
}

export default function CourseAttendance() {
  const { course, sessions } = useOutletContext();
  const { data, error, loading } = useApi(() => getCourseRoster(course.courseId), [course.courseId]);

  const students = data?.students ?? [];

  return (
    <div>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <>
          <MarkAttendanceForm sessions={sessions} students={students} />
          <CorrectAttendanceForm courseId={course.courseId} students={students} />
        </>
      )}
    </div>
  );
}
