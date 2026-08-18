import { useOutletContext } from 'react-router-dom';
import StatCard from '../../../components/StatCard';

export default function CourseOverview() {
  const { course } = useOutletContext();

  return (
    <div className="stat-grid">
      <StatCard label="Lecturer" value={`${course.lecturer.firstName} ${course.lecturer.lastName}`} />
      <StatCard label="Enrolled Students" value={course.enrolledCount} />
      <StatCard label="Sessions" value={course.timetable.length} />
    </div>
  );
}
