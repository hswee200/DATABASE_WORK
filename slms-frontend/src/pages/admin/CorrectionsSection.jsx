import { useState } from 'react';
import {
  deleteSubmission,
  deleteAttendance,
  getAllStudents,
  getAssessments,
  getStudentAttendanceRecords,
} from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import NameSearch from '../../components/NameSearch';
import StatusBanner from '../../components/StatusBanner';

// Deleting a submission or attendance record is a data-integrity correction
// (fixing an erroneous entry), not the academic act of grading or marking
// attendance itself - so it stays available to Admin. Submission deletes are
// soft (IsActive = FALSE); attendance deletes are a hard delete, per the
// backend design.
//
// Both forms are the same two-step shape: find the person by name, then
// pick which of their records to act on - never a typed SubmissionID or
// AttendanceID. `useRecords` loads that student's candidate records once a
// name is picked; `recordLabel` renders each option.
function DeleteRecordForm({ title, recordLabel, placeholder, useRecords, onDelete, describe }) {
  const { data: studentsData } = useApi(() => getAllStudents(), []);
  const [studentId, setStudentId] = useState('');
  const [selectedLabel, setSelectedLabel] = useState('');
  const [recordId, setRecordId] = useState('');
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const studentOptions = (studentsData?.students ?? []).map((s) => ({
    id: s.studentId,
    label: `${s.firstName} ${s.lastName}`,
  }));

  const { data: recordsData, loading: loadingRecords } = useRecords(studentId);
  const records = recordsData ?? [];

  function handleStudentSelect(id) {
    setStudentId(id);
    setRecordId('');
    if (id) {
      const match = studentOptions.find((o) => o.id === id);
      setSelectedLabel(match?.label ?? '');
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      const data = await onDelete(recordId);
      setSuccess(describe(data));
      setStudentId('');
      setSelectedLabel('');
      setRecordId('');
      setConfirmed(false);
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div style={{ marginBottom: '1.5rem' }}>
      <h3 style={{ fontSize: '0.95rem', marginBottom: '0.6rem' }}>{title}</h3>
      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 1rem' }}>
          <div className="field">
            <label htmlFor={`${title}-student`}>Student</label>
            <NameSearch
              id={`${title}-student`}
              options={studentOptions}
              onSelect={handleStudentSelect}
              placeholder={placeholder}
              selectedLabel={selectedLabel}
            />
          </div>
          <div className="field">
            <label htmlFor={`${title}-record`}>Record</label>
            <select
              id={`${title}-record`}
              value={recordId}
              onChange={(e) => setRecordId(e.target.value)}
              required
              disabled={!studentId || loadingRecords}
            >
              <option value="" disabled>
                {loadingRecords ? 'Loading…' : 'Choose…'}
              </option>
              {records.map((r) => (
                <option key={r.id} value={r.id}>
                  {recordLabel(r)}
                </option>
              ))}
            </select>
          </div>
        </div>
        <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.85rem', margin: '0.75rem 0' }}>
          <input type="checkbox" checked={confirmed} onChange={(e) => setConfirmed(e.target.checked)} />
          Confirm delete
        </label>
        <button type="submit" className="btn-primary" disabled={submitting || !confirmed || !recordId}>
          {submitting ? 'Deleting…' : 'Delete'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </div>
  );
}

// getAssessments already returns submissionId per assessment alongside
// names - filtering to rows that have one is exactly "this student's
// submissions," no new endpoint needed.
function useSubmissionRecords(studentId) {
  const { data, loading } = useApi(
    () => (studentId ? getAssessments(studentId) : Promise.resolve(null)),
    [studentId]
  );
  const records = (data?.assessments ?? [])
    .filter((a) => a.submissionId)
    .map((a) => ({ id: a.submissionId, courseName: a.courseName, assessmentName: a.assessmentName }));
  return { data: records, loading };
}

function useAttendanceRecordsList(studentId) {
  const { data, loading } = useApi(
    () => (studentId ? getStudentAttendanceRecords(studentId) : Promise.resolve(null)),
    [studentId]
  );
  const records = (data?.records ?? []).map((r) => ({
    id: r.attendanceId,
    courseName: r.courseName,
    attendanceDate: r.attendanceDate,
    status: r.status,
  }));
  return { data: records, loading };
}

export default function CorrectionsSection() {
  return (
    <section className="card">
      <h2>Data Corrections</h2>
      <DeleteRecordForm
        title="Delete a Submission"
        placeholder="e.g. Ama Owusu"
        useRecords={useSubmissionRecords}
        recordLabel={(r) => `${r.courseName} — ${r.assessmentName}`}
        onDelete={deleteSubmission}
        describe={(d) =>
          d.studentFirstName
            ? `Deleted ${d.studentFirstName} ${d.studentLastName}'s ${d.assessmentName} (${d.courseName}).`
            : 'Submission deleted.'
        }
      />
      <DeleteRecordForm
        title="Delete an Attendance Record"
        placeholder="e.g. Ama Owusu"
        useRecords={useAttendanceRecordsList}
        recordLabel={(r) => `${r.courseName} — ${r.attendanceDate} (${r.status})`}
        onDelete={deleteAttendance}
        describe={(d) =>
          d.studentFirstName
            ? `Deleted ${d.studentFirstName} ${d.studentLastName}'s record for ${d.courseName} on ${d.attendanceDate}.`
            : 'Attendance record deleted.'
        }
      />
    </section>
  );
}
