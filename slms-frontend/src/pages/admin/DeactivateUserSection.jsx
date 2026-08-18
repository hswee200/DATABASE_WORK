import { useState } from 'react';
import { deactivateUser, getAllUsers } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import NameSearch from '../../components/NameSearch';
import StatusBanner from '../../components/StatusBanner';

export default function DeactivateUserSection() {
  const { data } = useApi(() => getAllUsers(), []);
  const [userId, setUserId] = useState('');
  const [selectedLabel, setSelectedLabel] = useState('');
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const options = (data?.users ?? []).map((u) => ({
    id: u.userId,
    label: `${u.firstName} ${u.lastName} — ${u.roleName}${u.isActive ? '' : ' (already inactive)'}`,
  }));

  function handleSelect(id) {
    setUserId(id);
    if (id) {
      const match = options.find((o) => o.id === id);
      setSelectedLabel(match?.label ?? '');
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      const data = await deactivateUser(userId);
      setSuccess(
        `${data.username} (${data.roleName}) deactivated. They can no longer log in.`
      );
      setUserId('');
      setSelectedLabel('');
      setConfirmed(false);
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="card">
      <h2>Deactivate User Account</h2>
      <form onSubmit={handleSubmit} style={{ maxWidth: 360 }}>
        <div className="field">
          <label htmlFor="deactivateSearch">Find by name</label>
          <NameSearch
            id="deactivateSearch"
            options={options}
            onSelect={handleSelect}
            placeholder="e.g. Ama Owusu"
            selectedLabel={selectedLabel}
          />
        </div>
        <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
          <input
            type="checkbox"
            checked={confirmed}
            onChange={(e) => setConfirmed(e.target.checked)}
          />
          <span style={{ fontSize: '0.85rem' }}>
            I understand this account will no longer be able to log in.
          </span>
        </label>
        <button
          type="submit"
          className="btn-primary"
          disabled={submitting || !confirmed || !userId}
        >
          {submitting ? 'Deactivating…' : 'Deactivate'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </section>
  );
}
