import { useAuth } from '../../auth/AuthContext';
import { getLecturerLoad } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import StatusBanner from '../../components/StatusBanner';

export default function WorkloadSection() {
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getLecturerLoad(user.username), [user.username]);

  return (
    <section className="card">
      <h2>Workload Summary</h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        data && (
          <div style={{ display: 'flex', gap: '2rem' }}>
            <div>
              <div className="empty-note" style={{ fontStyle: 'normal' }}>Courses</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 700 }}>{data.numCourses}</div>
            </div>
            <div>
              <div className="empty-note" style={{ fontStyle: 'normal' }}>Students</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 700 }}>{data.numStudents}</div>
            </div>
          </div>
        )
      )}
    </section>
  );
}
