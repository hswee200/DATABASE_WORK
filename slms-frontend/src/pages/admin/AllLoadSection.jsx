import { getAllLecturerLoad } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';

const COLUMNS = [
  { key: 'lecturerId', label: 'Lecturer ID' },
  { key: 'name', label: 'Name', render: (r) => `${r.firstName} ${r.lastName}` },
  { key: 'numCourses', label: 'Courses' },
  { key: 'numStudents', label: 'Students' },
];

export default function AllLoadSection() {
  const { data, error, loading } = useApi(() => getAllLecturerLoad(), []);

  return (
    <section className="card">
      <h2>Lecturer Load — All Staff</h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={COLUMNS} rows={data?.lecturers} emptyMessage="No lecturers found." />
      )}
    </section>
  );
}
