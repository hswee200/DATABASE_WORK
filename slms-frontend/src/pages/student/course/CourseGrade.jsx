import { useOutletContext } from 'react-router-dom';
import { getCourseGrades } from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import DataTable from '../../../components/DataTable';
import StatCard from '../../../components/StatCard';
import StatusBanner from '../../../components/StatusBanner';

const COLUMNS = [
  { key: 'assessmentName', label: 'Assessment' },
  { key: 'assessmentCategory', label: 'Category' },
  {
    key: 'score',
    label: 'Score',
    render: (r) => (r.score === null ? 'Not yet graded' : `${r.score} / ${r.maxScore}`),
  },
  { key: 'weight', label: 'Weight', render: (r) => `${r.weight}%` },
];

// Every assessment in this course - graded or not - with its weight
// (Midsem 20% / Final 40% / Regular splits the rest) and a running average
// computed over graded work only, renormalized to 100% (so an ungraded
// assessment doesn't drag the number down - it just isn't counted yet).
export default function CourseGrade() {
  const { course } = useOutletContext();
  const { data, error, loading } = useApi(() => getCourseGrades(course.courseId), [course.courseId]);

  const self = data?.students?.[0];
  const rows = self?.assessments ?? [];

  return (
    <div>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <>
          <div style={{ marginBottom: '1rem' }}>
            <StatCard
              label="Course Average So Far"
              value={self?.averageSoFar === null || self?.averageSoFar === undefined ? '—' : `${self.averageSoFar}%`}
            />
          </div>
          <DataTable columns={COLUMNS} rows={rows} emptyMessage="No assessments for this course yet." />
        </>
      )}
    </div>
  );
}
