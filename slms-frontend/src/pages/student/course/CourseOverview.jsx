import { useState } from 'react';
import { useNavigate, useOutletContext } from 'react-router-dom';
import { useAuth } from '../../../auth/AuthContext';
import { unenrollStudent } from '../../../api/endpoints';
import StatCard from '../../../components/StatCard';
import StatusBanner from '../../../components/StatusBanner';

export default function CourseOverview() {
  const { course } = useOutletContext();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [confirming, setConfirming] = useState(false);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleUnenroll() {
    setError('');
    setSubmitting(true);
    try {
      await unenrollStudent(user.username, course.courseId);
      navigate('/student', { replace: true });
    } catch (err) {
      setError(err.message);
      setSubmitting(false);
    }
  }

  return (
    <div>
      <div className="stat-grid">
        <StatCard label="Day" value={course.dayOfWeek} />
        <StatCard
          label="Time"
          value={`${course.startTime.slice(0, 5)}–${course.endTime.slice(0, 5)}`}
        />
        <StatCard label="Room" value={course.room} />
      </div>

      <h2 className="section-heading">Enrollment</h2>
      <StatusBanner error={error} />
      {confirming ? (
        <div className="inline-form">
          <span className="empty-note" style={{ fontStyle: 'normal' }}>
            Unenroll from {course.courseCode}? This cannot be undone from here.
          </span>
          <button className="btn-primary" disabled={submitting} onClick={handleUnenroll}>
            {submitting ? 'Unenrolling…' : 'Confirm Unenroll'}
          </button>
          <button className="btn-secondary" disabled={submitting} onClick={() => setConfirming(false)}>
            Cancel
          </button>
        </div>
      ) : (
        <button className="btn-secondary" onClick={() => setConfirming(true)}>
          Unenroll from this Course
        </button>
      )}
    </div>
  );
}
