import { useState } from 'react';
import { getTranscript, getAllStudents } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import NameSearch from '../../components/NameSearch';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';

const COLUMNS = [
  { key: 'semester', label: 'Semester', render: (r) => `${r.semesterName} (${r.academicYear})` },
  { key: 'courseId', label: 'Course' },
  { key: 'courseName', label: 'Course Name' },
  {
    key: 'finalGradePercent',
    label: 'Final Grade',
    render: (r) => (r.finalGradePercent === null ? '—' : `${r.finalGradePercent}%`),
  },
  { key: 'letterGrade', label: 'Grade', render: (r) => r.letterGrade ?? '—' },
];

export default function TranscriptLookupSection() {
  const { data: studentsData } = useApi(() => getAllStudents(), []);
  const [studentId, setStudentId] = useState('');
  const [selectedLabel, setSelectedLabel] = useState('');
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const options = (studentsData?.students ?? []).map((s) => ({
    id: s.studentId,
    label: `${s.firstName} ${s.lastName}`,
  }));

  function handleSelect(id) {
    setStudentId(id);
    if (id) {
      const match = options.find((o) => o.id === id);
      setSelectedLabel(match?.label ?? '');
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setResult(null);
    setLoading(true);
    try {
      const data = await getTranscript(studentId);
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="card">
      <h2>Student Transcript Lookup</h2>
      <form className="inline-form" onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="lookupStudentSearch">Find by name</label>
          <NameSearch
            id="lookupStudentSearch"
            options={options}
            onSelect={handleSelect}
            placeholder="e.g. Ama Owusu"
            selectedLabel={selectedLabel}
          />
        </div>
        <button type="submit" className="btn-primary" disabled={loading || !studentId}>
          {loading ? 'Loading…' : 'Look Up'}
        </button>
      </form>
      <StatusBanner error={error} />
      {result && (
        <div style={{ marginTop: '1rem' }}>
          <p className="empty-note" style={{ fontStyle: 'normal', color: 'inherit' }}>
            <strong>
              {result.firstName} {result.lastName}
            </strong>{' '}
            ({result.studentId})
          </p>
          <DataTable columns={COLUMNS} rows={result.transcript} emptyMessage="No graded courses yet." />
        </div>
      )}
    </section>
  );
}
