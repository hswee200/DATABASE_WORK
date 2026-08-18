import { useOutletContext } from 'react-router-dom';
import StatCard from '../../../components/StatCard';

export default function CourseOverview() {
  const { course } = useOutletContext();

  return (
    <div className="stat-grid">
      <StatCard label="Day" value={course.dayOfWeek} />
      <StatCard label="Time" value={`${course.startTime.slice(0, 5)}–${course.endTime.slice(0, 5)}`} />
      <StatCard label="Room" value={course.room} />
      <StatCard label="Semester" value={`${course.semesterName} (${course.academicYear})`} />
    </div>
  );
}
