import { useState } from 'react';
import { createStudent, createLecturer, createAdmin } from '../../api/endpoints';
import StatusBanner from '../../components/StatusBanner';

// One config per role instead of three near-identical components - the three
// sp_create_* procedures share a signature (see backend usersController.js),
// so the form only needs to vary which endpoint it calls.
const ROLE_CONFIGS = {
  Student: { idField: 'studentId', create: createStudent },
  Lecturer: { idField: 'lecturerId', create: createLecturer },
  Admin: { idField: 'adminId', create: createAdmin },
};

const EMPTY_FORM = {
  email: '',
  password: '',
  firstName: '',
  lastName: '',
  dateOfBirth: '',
};

export default function CreateUserSection() {
  const [role, setRole] = useState('Student');
  const [form, setForm] = useState(EMPTY_FORM);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const config = ROLE_CONFIGS[role];

  function updateField(field, value) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  function handleRoleChange(nextRole) {
    setRole(nextRole);
    setForm(EMPTY_FORM);
    setError('');
    setSuccess('');
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);
    try {
      // No ID field anywhere here - UserID and the role ID
      // (StudentID/LecturerID/AdminID) are generated server-side, since
      // nobody should have to invent or remember "the next free ID."
      const payload = {
        email: form.email.trim(),
        password: form.password,
        firstName: form.firstName.trim(),
        lastName: form.lastName.trim(),
        dateOfBirth: form.dateOfBirth.trim() || undefined,
      };
      const result = await config.create(payload);
      const profileId = result[config.idField];
      setSuccess(`Created ${role.toLowerCase()} ${profileId} — ${result.firstName} ${result.lastName} (${result.email}).`);
      setForm(EMPTY_FORM);
    } catch (err) {
      // 400s carry a `details` array with every validation problem at once,
      // matching the backend's design so the admin isn't fixing one field per try.
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="card">
      <h2>Create User Account</h2>
      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
        {Object.keys(ROLE_CONFIGS).map((r) => (
          <button
            key={r}
            type="button"
            className={r === role ? 'btn-primary' : 'btn-secondary'}
            onClick={() => handleRoleChange(r)}
          >
            {r}
          </button>
        ))}
      </div>

      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 1rem' }}>
          <div className="field">
            <label htmlFor="firstName">First Name</label>
            <input
              id="firstName"
              value={form.firstName}
              onChange={(e) => updateField('firstName', e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="lastName">Last Name</label>
            <input
              id="lastName"
              value={form.lastName}
              onChange={(e) => updateField('lastName', e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              value={form.email}
              onChange={(e) => updateField('email', e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={form.password}
              onChange={(e) => updateField('password', e.target.value)}
              placeholder="8+ characters"
              required
            />
          </div>
          <div className="field">
            <label htmlFor="dateOfBirth">Date of Birth (optional)</label>
            <input
              id="dateOfBirth"
              type="date"
              value={form.dateOfBirth}
              onChange={(e) => updateField('dateOfBirth', e.target.value)}
            />
          </div>
        </div>
        <button type="submit" className="btn-primary" disabled={submitting}>
          {submitting ? 'Creating…' : `Create ${role}`}
        </button>
      </form>
      <StatusBanner error={error} success={success} />
    </section>
  );
}
