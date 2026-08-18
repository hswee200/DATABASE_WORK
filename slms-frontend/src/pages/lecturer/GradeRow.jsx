import { useState } from 'react';
import { recordGrade } from '../../api/endpoints';

// One row = one ungraded submission. submissionId is only ever read from the
// row data the backend supplied (see GradeSubmissionsSection.jsx) - the
// lecturer never types or sees it, only the score they're assigning.
export default function GradeRow({ submission, onDone }) {
  const [score, setScore] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleGrade() {
    setError('');
    setSubmitting(true);
    try {
      await recordGrade(submission.submissionId, Number(score));
      onDone();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
      <input
        type="number"
        step="0.01"
        min="0"
        value={score}
        onChange={(e) => setScore(e.target.value)}
        style={{ width: '5rem', padding: '0.35rem 0.5rem' }}
        placeholder="Score"
      />
      <button
        type="button"
        className="btn-primary"
        disabled={submitting || score === ''}
        onClick={handleGrade}
        style={{ padding: '0.35rem 0.7rem', fontSize: '0.8rem' }}
      >
        {submitting ? '…' : 'Submit'}
      </button>
      {error && <span style={{ color: 'var(--error)', fontSize: '0.8rem' }}>{error}</span>}
    </div>
  );
}
