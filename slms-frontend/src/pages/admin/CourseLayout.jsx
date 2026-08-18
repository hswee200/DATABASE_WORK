import { useParams, Outlet } from 'react-router-dom';
import { getCourseRoster } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import StatusBanner from '../../components/StatusBanner';

// getCourseRoster already returns course + lecturer + timetable in one call
// (Admin can always read it - canReadCourse), so it doubles as this course's
// detail context without a separate "get one course" endpoint. Navigation
// between tabs lives in the sidebar (see AdminLayout.jsx), which swaps to
// this course's nav while the route is under /courses/:courseId.
export default function CourseLayout() {
  const { courseId } = useParams();
  const { data, error, loading, reload } = useApi(() => getCourseRoster(courseId), [courseId]);

  if (loading) return <p className="empty-note">Loading…</p>;
  if (error) return <StatusBanner error={error} />;
  if (!data) return null;

  return (
    <div>
      <h1 className="page-title">
        {data.courseCode} — {data.courseName}
      </h1>
      <Outlet context={{ courseId, course: data, reload }} />
    </div>
  );
}
