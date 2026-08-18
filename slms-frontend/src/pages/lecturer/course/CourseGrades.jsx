import { useOutletContext } from 'react-router-dom';
import { getCourseGrades } from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import DataTable from '../../../components/DataTable';
import StatusBanner from '../../../components/StatusBanner';

// Gradebook: every enrolled student's every assessment in this course,
// graded or not, with its weight (Midsem 20% / Final 40% / Regular splits
// the rest) and a running average over graded work only, renormalized to
// 100%. One row per assessment per student, grouped visually by student.
export default function CourseGrades() {
  const { course } = useOutletContext();
  const { data, error, loading } = useApi(() => getCourseGrades(course.courseId), [course.courseId]);

  const students = data?.students ?? [];

  const rows = students.flatMap((s) =>
    s.assessments.map((a, i) => ({
      key: `${s.studentId}-${a.assessmentId}`,
      student: i === 0 ? `${s.firstName} ${s.lastName}` : '',
      average: i === 0 ? (s.averageSoFar === null ? '—' : `${s.averageSoFar}%`) : '',
      ...a,
    }))
  );

  const columns = [
    { key: 'student', label: 'Student' },
    { key: 'assessmentName', label: 'Assessment' },
    { key: 'assessmentCategory', label: 'Category' },
    {
      key: 'score',
      label: 'Score',
      render: (r) => (r.score === null ? 'Not yet graded' : `${r.score} / ${r.maxScore}`),
    },
    { key: 'weight', label: 'Weight', render: (r) => `${r.weight}%` },
    { key: 'average', label: 'Average So Far' },
  ];

  return (
    <div>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={columns} rows={rows} emptyMessage="No enrolled students yet." />
      )}
    </div>
  );
}
