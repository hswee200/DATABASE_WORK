import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { getAllLecturerLoad } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import StatCard from '../../components/StatCard';
import StatusBanner from '../../components/StatusBanner';

export default function AdminOverview() {
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getAllLecturerLoad(), []);

  const lecturers = data?.lecturers ?? [];
  const totalCourses = lecturers.reduce((sum, l) => sum + l.numCourses, 0);
  const totalStudents = lecturers.reduce((sum, l) => sum + l.numStudents, 0);

  return (
    <div>
      <h1 className="page-title">Welcome, {user.username}</h1>
      <StatusBanner error={error} />

      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <>
          <div className="stat-grid">
            <StatCard label="Lecturers" value={lecturers.length} />
            <StatCard label="Courses Running" value={totalCourses} />
            <StatCard label="Total Enrolments" value={totalStudents} />
          </div>

          <h2 className="section-heading">Quick Actions</h2>
          <div className="quick-links">
            <Link to="courses" className="btn-secondary">
              Browse Courses
            </Link>
            <Link to="transcripts" className="btn-secondary">
              Look Up a Transcript
            </Link>
            <Link to="load" className="btn-secondary">
              Lecturer Load
            </Link>
            <Link to="create-user" className="btn-primary">
              + Create User
            </Link>
          </div>
        </>
      )}
    </div>
  );
}
