import { useAuth } from '../../auth/AuthContext';
import { getLecturerTimetable } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';

const COLUMNS = [
  { key: 'dayOfWeek', label: 'Day' },
  { key: 'startTime', label: 'Start' },
  { key: 'endTime', label: 'End' },
  { key: 'courseCode', label: 'Course' },
  { key: 'courseName', label: 'Course Name' },
  { key: 'room', label: 'Room' },
  { key: 'semesterName', label: 'Semester' },
  { key: 'academicYear', label: 'Year' },
];

export default function LecturerTimetableSection() {
  const { user } = useAuth();
  const { data, error, loading } = useApi(
    () => getLecturerTimetable(user.username),
    [user.username]
  );

  return (
    <section className="card">
      <h2>Teaching Timetable</h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={COLUMNS} rows={data?.timetable} emptyMessage="No sessions scheduled." />
      )}
    </section>
  );
}
