import { useAuth } from '../../auth/AuthContext';
import { getTranscript } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatCard from '../../components/StatCard';
import StatusBanner from '../../components/StatusBanner';

const COLUMNS = [
  { key: 'courseId', label: 'Course' },
  { key: 'courseName', label: 'Course Name' },
  { key: 'creditHours', label: 'Credits' },
  {
    key: 'finalGradePercent',
    label: 'Final Grade',
    render: (r) => (r.finalGradePercent === null ? '—' : `${r.finalGradePercent}%`),
  },
  { key: 'letterGrade', label: 'Grade', render: (r) => r.letterGrade ?? '—' },
];

// Same per-course-per-semester shape as before, just grouped under a
// heading per semester instead of one flat table - plus that semester's
// GPA, and a running CGPA (cumulative across every semester up to and
// including the current one) from vw_student_gpa.
export default function TranscriptSection() {
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getTranscript(user.username), [user.username]);

  const bySemester = new Map();
  for (const row of data?.transcript ?? []) {
    if (!bySemester.has(row.semesterId)) bySemester.set(row.semesterId, []);
    bySemester.get(row.semesterId).push(row);
  }
  const gpaBySemester = new Map((data?.gpa ?? []).map((g) => [g.semesterId, g]));
  const latestCgpa = data?.gpa?.length ? data.gpa[data.gpa.length - 1].cgpa : null;

  return (
    <section className="card">
      <h2>
        Transcript
        {data && (
          <span className="muted-count">
            {' '}
            — {data.firstName} {data.lastName}
          </span>
        )}
      </h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <>
          <div style={{ marginBottom: '1.25rem' }}>
            <StatCard label="Cumulative GPA (CGPA)" value={latestCgpa === null ? '—' : latestCgpa.toFixed(2)} />
          </div>
          {data?.gpa?.length ? (
            data.gpa.map((g) => {
              const rows = bySemester.get(g.semesterId) ?? [];
              return (
                <div key={g.semesterId} style={{ marginBottom: '1.5rem' }}>
                  <h3 style={{ margin: '0 0 0.5rem' }}>
                    {g.semesterName} ({g.academicYear})
                    <span className="muted-count"> — GPA: {g.semesterGPA.toFixed(2)}</span>
                  </h3>
                  <DataTable columns={COLUMNS} rows={rows} emptyMessage="No graded courses this semester." />
                </div>
              );
            })
          ) : (
            <p className="empty-note">No graded courses yet.</p>
          )}
        </>
      )}
    </section>
  );
}
