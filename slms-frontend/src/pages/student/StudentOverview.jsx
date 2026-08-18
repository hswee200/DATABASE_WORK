import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { getStudentTimetable, getAssessments, getAttendance } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import CourseCard from '../../components/CourseCard';
import StatCard from '../../components/StatCard';
import StatusBanner from '../../components/StatusBanner';

// One card per course the student currently has a scheduled session for -
// the timetable is the closest thing to "my current courses" the API
// exposes, so it doubles as the course list here.
function uniqueCourses(timetable) {
  const seen = new Map();
  for (const row of timetable) {
    if (!seen.has(row.courseId)) {
      seen.set(row.courseId, row);
    }
  }
  return [...seen.values()];
}

function averageAttendance(rows) {
  const rates = rows.map((r) => r.attendanceRate).filter((r) => r !== null);
  if (rates.length === 0) return null;
  return Math.round(rates.reduce((sum, r) => sum + r, 0) / rates.length);
}

export default function StudentOverview() {
  const { user } = useAuth();
  const timetable = useApi(() => getStudentTimetable(user.username), [user.username]);
  const assessments = useApi(() => getAssessments(user.username), [user.username]);
  const attendance = useApi(() => getAttendance(user.username), [user.username]);

  const loading = timetable.loading || assessments.loading || attendance.loading;
  const error = timetable.error || assessments.error || attendance.error;

  const courses = timetable.data ? uniqueCourses(timetable.data.timetable) : [];
  const upcomingCount = assessments.data
    ? assessments.data.assessments.filter((a) => a.status === 'Upcoming').length
    : 0;
  const pastDueCount = assessments.data
    ? assessments.data.assessments.filter((a) => a.status === 'Past-Due').length
    : 0;
  const avgAttendance = attendance.data ? averageAttendance(attendance.data.attendance) : null;

  return (
    <div>
      <h1 className="page-title">Welcome, {user.username}</h1>
      <StatusBanner error={error} />

      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <>
          <div className="stat-grid">
            <StatCard label="Courses" value={courses.length} />
            <StatCard label="Upcoming Assessments" value={upcomingCount} />
            <StatCard label="Past-Due" value={pastDueCount} />
            <StatCard
              label="Avg. Attendance"
              value={avgAttendance === null ? '—' : `${avgAttendance}%`}
            />
          </div>

          <h2 className="section-heading">My Courses</h2>
          {courses.length === 0 ? (
            <p className="empty-note">No scheduled courses.</p>
          ) : (
            <div className="course-grid">
              {courses.map((c) => (
                <CourseCard
                  key={c.courseId}
                  to={`courses/${c.courseId}`}
                  courseId={c.courseId}
                  courseCode={c.courseCode}
                  courseName={c.courseName}
                  meta={`${c.dayOfWeek} · ${c.startTime.slice(0, 5)}–${c.endTime.slice(0, 5)}`}
                />
              ))}
            </div>
          )}

          <div className="quick-links">
            <Link to="transcript" className="btn-secondary">
              View Transcript
            </Link>
            <Link to="timetable" className="btn-secondary">
              Full Timetable
            </Link>
            <Link to="assessments" className="btn-secondary">
              All Assessments
            </Link>
          </div>
        </>
      )}
    </div>
  );
}
