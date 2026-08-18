import { getAdminReports } from '../../api/endpoints';
import { useApi } from '../../api/useApi';
import DataTable from '../../components/DataTable';
import StatusBanner from '../../components/StatusBanner';

// Six institution-wide oversight views, no per-user scoping - Admin is the
// registrar/oversight role (see reportsController.js's getAdminReports).
export default function ReportsSection() {
  const { data, error, loading } = useApi(() => getAdminReports(), []);

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

  const neverAbsentColumns = [
    { key: 'student', label: 'Student', render: (r) => `${r.firstName} ${r.lastName}` },
    { key: 'studentId', label: 'Student ID' },
  ];

  const noAssessmentsColumns = [
    { key: 'courseCode', label: 'Code' },
    { key: 'courseName', label: 'Course' },
  ];

  const enrollmentColumns = [
    { key: 'courseName', label: 'Course' },
    { key: 'enrolledStudents', label: 'Enrolled' },
    { key: 'enrollmentRank', label: 'Rank' },
  ];

  const performanceColumns = [
    { key: 'courseName', label: 'Course' },
    { key: 'avgScorePct', label: 'Avg Score %', render: (r) => (r.avgScorePct ?? '—') },
    { key: 'lowPerformanceRank', label: 'Rank (lowest first)' },
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
              <h2>Students Never Marked Absent</h2>
              <DataTable columns={neverAbsentColumns} rows={data.neverAbsentStudents} emptyMessage="No qualifying students." />
            </section>
            <section className="card">
              <h2>Courses Without Assessments</h2>
              <DataTable columns={noAssessmentsColumns} rows={data.coursesWithoutAssessments} emptyMessage="Every course has at least one assessment." />
            </section>
            <section className="card">
              <h2>Course Enrollment Ranking</h2>
              <DataTable columns={enrollmentColumns} rows={data.courseEnrollmentRanking} emptyMessage="No enrollments." />
            </section>
            <section className="card">
              <h2>Course Performance Ranking (Lowest First)</h2>
              <DataTable columns={performanceColumns} rows={data.coursePerformanceRanking} emptyMessage="No scored submissions yet." />
            </section>
          </>
        )
      )}
    </div>
  );
}
