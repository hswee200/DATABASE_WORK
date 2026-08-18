import { useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getCourseAssessments, createAssessment, updateAssessment } from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import DataTable from '../../../components/DataTable';
import StatusBanner from '../../../components/StatusBanner';

const ASSESSMENT_TYPES = ['Assignment', 'Quiz', 'Project', 'Lab', 'Exam'];

const COLUMNS = [
  { key: 'assessmentId', label: 'ID' },
  { key: 'assessmentName', label: 'Name' },
  { key: 'assessmentType', label: 'Type' },
  { key: 'assessmentCategory', label: 'Category' },
  { key: 'maxScore', label: 'Max Score' },
  { key: 'dueDate', label: 'Due Date' },
];

function CreateAssessmentForm({ courseId, onCreated }) {
  const [assessmentType, setAssessmentType] = useState(ASSESSMENT_TYPES[0]);
  const [assessmentName, setAssessmentName] = useState('');
  const [maxScore, setMaxScore] = useState('');
  const [dueDate, setDueDate] = useState('');
  // Neither checked -> 'Regular', which splits the leftover weight evenly
  // with every other Regular assessment in the course (see
  // vw_course_grades). At most one Midsem and one Final per course - the
  // backend rejects a second one with a 409, surfaced below via error.
  const [assessmentCategory, setAssessmentCategory] = useState('Regular');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      // No assessmentId here - the backend generates it (same pattern as
      // sp_enroll_student), so nobody has to invent the next free AS-number.
      const data = await createAssessment(courseId, {
        assessmentType,
        assessmentName: assessmentName.trim(),
        maxScore: Number(maxScore),
        dueDate,
        assessmentCategory,
      });
      setSuccess(`Created ${data.assessmentName}.`);
      setAssessmentName('');
      setMaxScore('');
      setDueDate('');
      setAssessmentCategory('Regular');
      onCreated();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <h2 className="section-heading">Create Assessment</h2>
      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 1rem' }}>
          <div className="field">
            <label htmlFor="newAssessmentType">Type</label>
            <select
              id="newAssessmentType"
              value={assessmentType}
              onChange={(e) => setAssessmentType(e.target.value)}
            >
              {ASSESSMENT_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="newAssessmentName">Name</label>
            <input
              id="newAssessmentName"
              value={assessmentName}
              onChange={(e) => setAssessmentName(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="newMaxScore">Max Score</label>
            <input
              id="newMaxScore"
              type="number"
              step="0.01"
              min="0"
              value={maxScore}
              onChange={(e) => setMaxScore(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="newDueDate">Due Date</label>
            <input
              id="newDueDate"
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              required
            />
          </div>
        </div>
        <div style={{ display: 'flex', gap: '1.5rem', margin: '0.5rem 0 1rem' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontWeight: 400 }}>
            <input
              type="checkbox"
              checked={assessmentCategory === 'Midsem'}
              onChange={(e) => setAssessmentCategory(e.target.checked ? 'Midsem' : 'Regular')}
            />
            Midsem exam (20% of course grade)
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontWeight: 400 }}>
            <input
              type="checkbox"
              checked={assessmentCategory === 'Final'}
              onChange={(e) => setAssessmentCategory(e.target.checked ? 'Final' : 'Regular')}
            />
            Final exam (40% of course grade)
          </label>
        </div>
        <button
          type="submit"
          className="btn-primary"
          disabled={submitting || !assessmentName.trim() || maxScore === '' || !dueDate}
        >
          {submitting ? 'Creating…' : 'Create'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </div>
  );
}

function EditAssessmentForm({ assessments, onUpdated }) {
  const [assessmentId, setAssessmentId] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [maxScore, setMaxScore] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      const data = await updateAssessment(assessmentId, dueDate, Number(maxScore));
      setSuccess(`${data.assessmentName} updated: due ${data.dueDate}, max ${data.maxScore}.`);
      onUpdated();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <h2 className="section-heading">Edit Assessment</h2>
      <form className="inline-form" onSubmit={handleSubmit}>
        <div className="field">
          <label htmlFor="editAssessmentId">Assessment</label>
          <select
            id="editAssessmentId"
            value={assessmentId}
            onChange={(e) => setAssessmentId(e.target.value)}
            required
          >
            <option value="" disabled>
              Choose…
            </option>
            {assessments.map((a) => (
              <option key={a.assessmentId} value={a.assessmentId}>
                {a.assessmentName}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="editDueDate">Due Date</label>
          <input
            id="editDueDate"
            type="date"
            value={dueDate}
            onChange={(e) => setDueDate(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="editMaxScore">Max Score</label>
          <input
            id="editMaxScore"
            type="number"
            step="0.01"
            min="0"
            value={maxScore}
            onChange={(e) => setMaxScore(e.target.value)}
            required
          />
        </div>
        <button
          type="submit"
          className="btn-primary"
          disabled={submitting || !assessmentId || !dueDate || maxScore === ''}
        >
          {submitting ? 'Saving…' : 'Save Changes'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </div>
  );
}

export default function CourseAssessments() {
  const { course } = useOutletContext();
  const { data, error, loading, reload } = useApi(
    () => getCourseAssessments(course.courseId),
    [course.courseId]
  );

  const assessments = data?.assessments ?? [];

  return (
    <div>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={COLUMNS} rows={assessments} emptyMessage="No assessments yet." />
      )}

      <CreateAssessmentForm courseId={course.courseId} onCreated={reload} />

      {assessments.length > 0 && <EditAssessmentForm assessments={assessments} onUpdated={reload} />}
    </div>
  );
}
