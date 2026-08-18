import { useState } from 'react';
import { submitAssessment, resubmitAssessment } from '../../../api/endpoints';

// Whether Submit or Resubmit is the currently valid action is decided purely
// by whether the assessment already has a submissionId - the same
// prerequisite the backend enforces (sp_resubmit_assessment rejects a
// resubmit with nothing to replace, sp_submit_assessment rejects a second
// first-submit). No SubmissionID is typed here - the backend generates it
// server-side and resolves which existing submission to deactivate by
// StudentID+AssessmentID, so a student never sees or invents that ID.
export default function SubmitAction({ assessment, onDone }) {
  const isResubmit = Boolean(assessment.submissionId);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function run(action) {
    setError('');
    setSubmitting(true);
    try {
      if (action === 'submit') {
        await submitAssessment(assessment.assessmentId);
      } else {
        await resubmitAssessment(assessment.assessmentId);
      }
      onDone();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
      <button
        type="button"
        className="btn-primary"
        disabled={submitting || isResubmit}
        onClick={() => run('submit')}
        style={{ padding: '0.35rem 0.7rem', fontSize: '0.8rem' }}
      >
        {submitting ? '…' : 'Submit'}
      </button>
      <button
        type="button"
        className="btn-warning"
        disabled={submitting || !isResubmit}
        onClick={() => run('resubmit')}
        style={{ padding: '0.35rem 0.7rem', fontSize: '0.8rem' }}
      >
        {submitting ? '…' : 'Resubmit'}
      </button>
      {error && <span style={{ color: 'var(--error)', fontSize: '0.8rem' }}>{error}</span>}
    </div>
  );
}
