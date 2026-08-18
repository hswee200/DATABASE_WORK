import { useAuth } from '../../auth/AuthContext';
import { getAssessments, getBelowClassAverage, getUpcomingDeadlines } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';

// The three statuses the view computes, in the display order requested,
// paired with the CSS class that colors each column.
const GROUPS = [
  { status: 'Upcoming', className: 'status-upcoming' },
  { status: 'Past-Due', className: 'status-past-due' },
  { status: 'Submitted', className: 'status-submitted' },
];

function groupByStatus(assessments) {
  const groups = { Upcoming: [], 'Past-Due': [], Submitted: [] };
  for (const a of assessments) {
    (groups[a.status] ?? (groups[a.status] = [])).push(a);
  }
  return groups;
}

// "How am I doing?" - courses where this student's average is below the
// class average, from vw_below_class_average.
function BelowAveragePanel({ studentId }) {
  const { data, error, loading } = useApi(() => getBelowClassAverage(studentId), [studentId]);

  const columns = [
    { key: 'courseName', label: 'Course' },
    { key: 'studentAvg', label: 'Your Avg', render: (r) => (r.studentAvg ?? '—') },
    { key: 'classAvg', label: 'Class Avg', render: (r) => (r.classAvg == null ? '—' : r.classAvg.toFixed(2)) },
  ];

  return (
    <section className="card">
      <h2>How Am I Doing?</h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable
          columns={columns}
          rows={data?.belowAverage}
          emptyMessage="You're at or above the class average in every course."
        />
      )}
    </section>
  );
}

// Upcoming deadlines ranked within each enrolled course, from
// vw_upcoming_deadlines_ranked.
function UpcomingDeadlinesPanel({ studentId }) {
  const { data, error, loading } = useApi(() => getUpcomingDeadlines(studentId), [studentId]);

  const columns = [
    { key: 'courseName', label: 'Course' },
    { key: 'assessmentName', label: 'Assessment' },
    { key: 'dueDate', label: 'Due Date' },
    { key: 'daysRemaining', label: 'Days Remaining' },
    { key: 'deadlineRankInCourse', label: 'Rank in Course' },
  ];

  return (
    <section className="card">
      <h2>Upcoming Deadlines</h2>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={columns} rows={data?.upcomingDeadlines} emptyMessage="No upcoming deadlines." />
      )}
    </section>
  );
}

export default function AssessmentBoard() {
  const { user } = useAuth();
  const { data, error, loading } = useApi(() => getAssessments(user.username), [user.username]);

  const groups = data ? groupByStatus(data.assessments) : null;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <section className="card">
        <h2>Assessments</h2>
        <StatusBanner error={error} />
        {loading ? (
          <p className="empty-note">Loading…</p>
        ) : (
          <div className="board">
            {GROUPS.map(({ status, className }) => (
              <div key={status} className={`board-column ${className}`}>
                <h3>
                  {status} <span className="count-pill">{groups[status].length}</span>
                </h3>
                {groups[status].length === 0 ? (
                  <p className="empty-note">None.</p>
                ) : (
                  <ul className="board-list">
                    {groups[status].map((a) => (
                      <li key={a.assessmentId}>
                        <div className="assessment-name">{a.assessmentName}</div>
                        <div className="assessment-meta">
                          {a.courseCode ?? a.courseId} — {a.courseName} — due {a.dueDate}
                        </div>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            ))}
          </div>
        )}
      </section>
      <UpcomingDeadlinesPanel studentId={user.username} />
      <BelowAveragePanel studentId={user.username} />
    </div>
  );
}
