import { useAuth } from '../../auth/AuthContext';
import { getLecturerReports } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';

// Three views granted to lecturer_role that aren't scoped to a single
// course (vw_course_score_ranking, vw_late_submissions,
// vw_upcoming_deadlines_ranked) - scoped server-side to this lecturer's own
// courses (see reportsController.js's getLecturerReports).
export default function ReportsSection() {
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getLecturerReports(user.username), [user.username]);

  const scoreRankingColumns = [
    { key: 'courseName', label: 'Course' },
    { key: 'student', label: 'Student', render: (r) => `${r.firstName} ${r.lastName}` },
    { key: 'avgScore', label: 'Avg Score', render: (r) => r.avgScore ?? '—' },
    { key: 'rankInCourse', label: 'Rank' },
  ];

  const lateColumns = [
    { key: 'student', label: 'Student', render: (r) => `${r.firstName} ${r.lastName}` },
    { key: 'courseName', label: 'Course' },
    { key: 'assessmentName', label: 'Assessment' },
    { key: 'dueDate', label: 'Due Date' },
    { key: 'submissionDate', label: 'Submitted' },
    { key: 'daysLate', label: 'Days Late' },
  ];

  const deadlineColumns = [
    { key: 'courseName', label: 'Course' },
    { key: 'assessmentName', label: 'Assessment' },
    { key: 'dueDate', label: 'Due Date' },
    { key: 'daysRemaining', label: 'Days Remaining' },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        data && (
          <>
            <section className="card">
              <h2>Score Ranking by Course</h2>
              <DataTable columns={scoreRankingColumns} rows={data.courseScoreRanking} emptyMessage="No scored submissions yet." />
            </section>
            <section className="card">
              <h2>Late Submissions</h2>
              <DataTable columns={lateColumns} rows={data.lateSubmissions} emptyMessage="No late submissions." />
            </section>
            <section className="card">
              <h2>Upcoming Deadlines</h2>
              <DataTable columns={deadlineColumns} rows={data.upcomingDeadlines} emptyMessage="No upcoming deadlines." />
            </section>
          </>
        )
      )}
    </div>
  );
}
