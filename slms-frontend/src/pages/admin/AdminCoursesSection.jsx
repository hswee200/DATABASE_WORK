import { useAuth } from '../../auth/AuthContext';
import { getAllCourses } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import CourseCard from '../../components/CourseCard';
import StatusBanner from '../../components/StatusBanner';

// The entry point into a specific course's context - mirrors the clickable
// course cards Student/Lecturer get from their own Overview, except Admin
// has no "my courses," so this browses every course instead.
export default function AdminCoursesSection() {
  useAuth();
  const { data, error, loading } = useApi(() => getAllCourses(), []);

  const courses = data?.courses ?? [];

  return (
    <div>
      <h1 className="page-title">Courses</h1>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : courses.length === 0 ? (
        <p className="empty-note">No courses found.</p>
      ) : (
        <div className="course-grid">
          {courses.map((c) => (
            <CourseCard
              key={c.courseId}
              to={`${c.courseId}`}
              courseId={c.courseId}
              courseCode={c.courseCode}
              courseName={c.courseName}
              meta={`${c.lecturerFirstName} ${c.lecturerLastName} · ${c.semesterName} (${c.academicYear})`}
            />
          ))}
        </div>
      )}
    </div>
  );
}
