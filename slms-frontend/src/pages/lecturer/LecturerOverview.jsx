import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { getLecturerTimetable, getLecturerLoad } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import CourseCard from '../../components/CourseCard';
import StatCard from '../../components/StatCard';
import StatusBanner from '../../components/StatusBanner';

function uniqueCourses(timetable) {
  const seen = new Map();
  for (const row of timetable) {
    if (!seen.has(row.courseId)) {
      seen.set(row.courseId, row);
    }
  }
  return [...seen.values()];
}

export default function LecturerOverview() {
  const { user } = useAuth();
  const timetable = useApi(() => getLecturerTimetable(user.username), [user.username]);
  const load = useApi(() => getLecturerLoad(user.username), [user.username]);

  const loading = timetable.loading || load.loading;
  const error = timetable.error || load.error;
  const courses = timetable.data ? uniqueCourses(timetable.data.timetable) : [];

  return (
    <div>
      <h1 className="page-title">Welcome, {user.username}</h1>
      <StatusBanner error={error} />

      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <>
          <div className="stat-grid">
            <StatCard label="Courses Teaching" value={load.data?.numCourses ?? '—'} />
            <StatCard label="Total Students" value={load.data?.numStudents ?? '—'} />
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
            <Link to="timetable" className="btn-secondary">
              Full Timetable
            </Link>
          </div>
          <p className="empty-note" style={{ marginTop: '0.75rem' }}>
            Roster, grading, assessments, and attendance are inside each course above.
          </p>
        </>
      )}
    </div>
  );
}
