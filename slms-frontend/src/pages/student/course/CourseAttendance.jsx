import { useOutletContext } from 'react-router-dom';
import { useAuth } from '../../../auth/AuthContext';
import { getAttendance } from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import StatCard from '../../../components/StatCard';
import StatusBanner from '../../../components/StatusBanner';

export default function CourseAttendance() {
  const { course } = useOutletContext();
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getAttendance(user.username), [user.username]);

  const row = data?.attendance.find((a) => a.courseId === course.courseId);

  return (
    <div>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : !row ? (
        <p className="empty-note">No attendance recorded for this course.</p>
      ) : (
        <div className="stat-grid">
          <StatCard label="Present" value={row.timesPresent} />
          <StatCard label="Absent" value={row.timesAbsent} />
          <StatCard label="Late" value={row.timesLate} />
          <StatCard label="Total Sessions" value={row.totalSessions} />
          <StatCard
            label="Attendance Rate"
            value={row.attendanceRate === null ? '—' : `${row.attendanceRate}%`}
          />
        </div>
      )}
    </div>
  );
}
