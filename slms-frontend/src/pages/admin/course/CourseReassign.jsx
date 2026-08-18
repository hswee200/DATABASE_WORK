import { useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { reassignCourseLecturer, getAllLecturers } from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import StatusBanner from '../../../components/StatusBanner';

export default function CourseReassign() {
  const { courseId, course, reload } = useOutletContext();
  const { data } = useApi(() => getAllLecturers(), []);
  const [lecturerId, setLecturerId] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const lecturers = data?.lecturers ?? [];

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      const data = await reassignCourseLecturer(courseId, lecturerId);
      setSuccess(`${data.courseName} is now taught by ${data.lecturerFirstName} ${data.lecturerLastName}.`);
      setLecturerId('');
      reload();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <p className="empty-note" style={{ fontStyle: 'normal', color: 'inherit' }}>
        Currently taught by <strong>{course.lecturer.firstName} {course.lecturer.lastName}</strong>.
      </p>
      <form className="inline-form" onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="newLecturer">New lecturer</label>
          <select
            id="newLecturer"
            value={lecturerId}
            onChange={(e) => setLecturerId(e.target.value)}
            required
          >
            <option value="" disabled>
              Choose…
            </option>
            {lecturers.map((l) => (
              <option key={l.lecturerId} value={l.lecturerId}>
                {l.firstName} {l.lastName}
              </option>
            ))}
          </select>
        </div>
        <button type="submit" className="btn-primary" disabled={submitting || !lecturerId}>
          {submitting ? 'Saving…' : 'Reassign'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </div>
  );
}
