import { useAuth } from '../../auth/AuthContext';
import { getAttendance } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';

const COLUMNS = [
  { key: 'courseId', label: 'Course' },
  { key: 'courseName', label: 'Course Name' },
  { key: 'timesPresent', label: 'Present' },
  { key: 'timesAbsent', label: 'Absent' },
  { key: 'timesLate', label: 'Late' },
  { key: 'totalSessions', label: 'Total Sessions' },
  {
    key: 'attendanceRate',
    label: 'Attendance Rate',
    render: (r) => (r.attendanceRate === null ? '—' : `${r.attendanceRate}%`),
  },
];

export default function AttendanceSection() {
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getAttendance(user.username), [user.username]);

  return (
    <section className="card">
      <h2>Attendance</h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={COLUMNS} rows={data?.attendance} emptyMessage="No attendance recorded." />
      )}
    </section>
  );
}
