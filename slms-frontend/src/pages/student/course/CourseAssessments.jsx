import { useOutletContext } from 'react-router-dom';
import { useAuth } from '../../../auth/AuthContext';
import { getAssessments } from '../../../api/endpoints';
import { useApi } from '../../../api/useApi';
import DataTable from '../../../components/DataTable';
import StatusBanner from '../../../components/StatusBanner';
import SubmitAction from './SubmitAction';

export default function CourseAssessments() {
  const { course } = useOutletContext();
  const { user } = useAuth();
  const { data, error, loading, reload } = useApi(
    () => getAssessments(user.username),
    [user.username]
  );

  const rows = data?.assessments.filter((a) => a.courseId === course.courseId) ?? [];

  // Submit only makes sense before a submission exists, Resubmit only after -
  // the column shows whichever one currently applies, per assessment.
  const columns = [
    { key: 'assessmentName', label: 'Assessment' },
    { key: 'dueDate', label: 'Due Date' },
    { key: 'status', label: 'Status' },
    {
      key: 'action',
      label: 'Submit / Resubmit',
      render: (r) => <SubmitAction assessment={r} onDone={reload} />,
    },
  ];

  return (
    <div>
      <StatusBanner error={error} />
      {loading ? (
        <p className="empty-note">Loading…</p>
      ) : (
        <DataTable columns={columns} rows={rows} emptyMessage="No assessments for this course." />
      )}
    </div>
  );
}
