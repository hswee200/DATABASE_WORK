import { useParams, Outlet } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { getStudentTimetable } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import StatusBanner from '../../components/StatusBanner';

// The course this page is scoped to, looked up once here from the timetable
// (the only source that has schedule + name + code together) and handed
// down to every tab via Outlet context, so each tab doesn't re-derive it.
// Navigation between tabs lives in the sidebar (see StudentLayout.jsx), which
// swaps to this course's nav while the route is under /courses/:courseId.
export default function CourseLayout() {
  const { courseId } = useParams();
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getStudentTimetable(user.username), [user.username]);

  const course = data?.timetable.find((c) => c.courseId === courseId);

  if (loading) return <p className="empty-note">Loading…</p>;
  if (error) return <StatusBanner error={error} />;
  if (!course) {
    return <StatusBanner error="This course is not part of your current schedule." />;
  }

  return (
    <div>
      <h1 className="page-title">
        {course.courseCode} — {course.courseName}
      </h1>
      <Outlet context={{ course }} />
    </div>
  );
}
