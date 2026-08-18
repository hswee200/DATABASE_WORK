import { getUngradedSubmissions } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';
import GradeRow from './GradeRow';

// Lists ungraded submissions across ALL of this lecturer's courses by
// student/course/assessment name rather than asking them to type a raw
// SubmissionID. Backed by vw_ungraded_submissions, which carries no
// CourseID - so this is a general page, not a per-course tab. A row
// disappears once graded, since the backend query filters Score IS NULL.
export default function GradeSubmissionsSection() {
  const { data, error, loading, reload } = useApi(() => getUngradedSubmissions(), []);

  const rows = data?.submissions ?? [];

  const columns = [
    { key: 'student', label: 'Student', render: (r) => `${r.studentFirstName} ${r.studentLastName}` },
    { key: 'courseName', label: 'Course' },
    { key: 'assessmentName', label: 'Assessment' },
    { key: 'submissionDate', label: 'Submission Date' },
    {
      key: 'score',
      label: 'Score',
      render: (r) => <GradeRow submission={r} onDone={reload} />,
    },
  ];

  return (
    <section className="card">
      <h2>Grade Submissions</h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={columns} rows={rows} emptyMessage="No ungraded submissions." />
      )}
    </section>
  );
}
