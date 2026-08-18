import { useParams, Outlet } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { getLecturerTimetable } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import StatusBanner from '../../components/StatusBanner';

// Navigation between tabs lives in the sidebar (see LecturerLayout.jsx),
// which swaps to this course's nav while the route is under /courses/:courseId.
export default function CourseLayout() {
  const { courseId } = useParams();
  const { user } = useAuth();
  const { data, error, loading } = useApi(
    () => getLecturerTimetable(user.username),
    [user.username]
  );

  // A course can have more than one scheduled session (e.g. lecture + lab),
  // so every matching row is kept - Mark Attendance needs to pick a specific
  // TimetableID, not just "the course."
  const sessions = data?.timetable.filter((c) => c.courseId === courseId) ?? [];
  const course = sessions[0];

  if (loading) return <p className="empty-note">Loading…</p>;
  if (error) return <StatusBanner error={error} />;
  if (!course) {
    return <StatusBanner error="This course is not part of your teaching schedule." />;
  }

  return (
    <div>
      <h1 className="page-title">
        {course.courseCode} — {course.courseName}
      </h1>
      <Outlet context={{ course, sessions }} />
    </div>
  );
}
