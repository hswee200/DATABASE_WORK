import { useOutletContext } from 'react-router-dom';
import { getCourseRoster } from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import DataTable from '../../../components/DataTable';
import StatusBanner from '../../../components/StatusBanner';

const COLUMNS = [
  { key: 'studentId', label: 'Student ID' },
  { key: 'name', label: 'Name', render: (r) => `${r.firstName} ${r.lastName}` },
  { key: 'enrollmentDate', label: 'Enrolled' },
];

export default function CourseRoster() {
  const { course } = useOutletContext();
  const { data, error, loading } = useApi(() => getCourseRoster(course.courseId), [course.courseId]);

  return (
    <div>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={COLUMNS} rows={data?.students} emptyMessage="No students enrolled yet." />
      )}
    </div>
  );
}
