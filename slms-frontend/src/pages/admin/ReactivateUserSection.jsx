import { useState } from 'react';
import { reactivateUser, getAllUsers } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import NameSearch from '../../components/NameSearch';
import StatusBanner from '../../components/StatusBanner';

// Only deactivated accounts are offered here - there is nothing to do for an
// already-active one, so it is filtered out rather than just labeled.
export default function ReactivateUserSection() {
  const { data } = useApi(() => getAllUsers(), []);
  const [userId, setUserId] = useState('');
  const [selectedLabel, setSelectedLabel] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const options = (data?.users ?? [])
    .filter((u) => !u.isActive)
    .map((u) => ({
      id: u.userId,
      label: `${u.firstName} ${u.lastName} — ${u.roleName}`,
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
      const data = await reactivateUser(userId);
      setSuccess(`${data.username} (${data.roleName}) reactivated. They can log in again.`);
      setUserId('');
      setSelectedLabel('');
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="card">
      <h2>Reactivate User Account</h2>
      <form onSubmit={handleSubmit} style={{ maxWidth: 360 }}>
        <div className="field">
          <label htmlFor="reactivateSearch">Find by name</label>
          <NameSearch
            id="reactivateSearch"
            options={options}
            onSelect={handleSelect}
            placeholder={options.length ? 'e.g. Ama Owusu' : 'No deactivated accounts'}
            selectedLabel={selectedLabel}
          />
        </div>
        <button type="submit" className="btn-primary" disabled={submitting || !userId}>
          {submitting ? 'Reactivating…' : 'Reactivate'}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </section>
  );
}
