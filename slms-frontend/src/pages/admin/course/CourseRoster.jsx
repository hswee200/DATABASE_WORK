import { useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { unenrollStudent } from '../../../api/endpoints';
import DataTable from '../../../components/DataTable';

function UnenrollButton({ courseId, studentId, onDone }) {
  const [confirming, setConfirming] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  async function handleConfirm() {
    setSubmitting(true);
    setError('');
    try {
      await unenrollStudent(studentId, courseId);
      onDone();
    } catch (err) {
      setError(err.message);
      setSubmitting(false);
    }
  }

  if (confirming) {
    return (
      <span style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
        <button
          className="btn-primary"
          style={{ padding: '0.3rem 0.6rem', fontSize: '0.8rem' }}
          disabled={submitting}
          onClick={handleConfirm}
        >
          {submitting ? '…' : 'Confirm'}
        </button>
        <button
          className="btn-secondary"
          style={{ padding: '0.3rem 0.6rem', fontSize: '0.8rem' }}
          disabled={submitting}
          onClick={() => setConfirming(false)}
        >
          Cancel
        </button>
        {error && <span style={{ color: 'var(--error)', fontSize: '0.8rem' }}>{error}</span>}
      </span>
    );
  }

  return (
    <button
      className="btn-secondary"
      style={{ padding: '0.3rem 0.6rem', fontSize: '0.8rem' }}
      onClick={() => setConfirming(true)}
    >
      Unenroll
    </button>
  );
}

export default function CourseRoster() {
  const { courseId, course, reload } = useOutletContext();

  const columns = [
    { key: 'studentId', label: 'Student ID' },
    { key: 'name', label: 'Name', render: (r) => `${r.firstName} ${r.lastName}` },
    { key: 'enrollmentDate', label: 'Enrolled' },
    {
      key: 'action',
      label: '',
      render: (r) => (
        <UnenrollButton courseId={courseId} studentId={r.studentId} onDone={reload} />
      ),
    },
  ];

  return (
    <DataTable columns={columns} rows={course.students} emptyMessage="No students enrolled yet." />
  );
}
