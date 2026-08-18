import { useState } from 'react';
import { changeOwnPassword } from '../../api/endpoints';
import StatusBanner from '../../components/StatusBanner';

// Identical for all three roles - the endpoint is always scoped to the
// caller's own account via their token, never a userId the client supplies.
export default function ChangePasswordSection() {
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (newPassword !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setSubmitting(true);
    try {
      await changeOwnPassword(newPassword);
      setSuccess('Password changed.');
      setNewPassword('');
      setConfirmPassword('');
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="card">
      <h2>Change Password</h2>
      <form onSubmit={handleSubmit} style={{ maxWidth: 360 }}>
        <div className="field">
          <label htmlFor="newPassword">New Password</label>
          <input
            id="newPassword"
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            placeholder="8+ characters"
            required
          />
        </div>
        <div className="field">
          <label htmlFor="confirmPassword">Confirm New Password</label>
          <input
            id="confirmPassword"
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
          />
        </div>
        <button type="submit" className="btn-primary" disabled={submitting}>
          {submitting ? 'Saving…' : 'Change Password'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </section>
  );
}
