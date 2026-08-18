import { useMatch } from 'react-router-dom';
import AppShell from '../../components/AppShell';

const GENERAL_NAV_ITEMS = [
  { path: '/lecturer', label: 'Overview', icon: '🏠', end: true },
  { path: '/lecturer/timetable', label: 'Timetable', icon: '🗓️' },
  { path: '/lecturer/workload', label: 'Workload', icon: '📊' },
  { path: '/lecturer/grade', label: 'Grade Submission', icon: '✏️' },
  { path: '/lecturer/reports', label: 'Reports', icon: '📈' },
  { path: '/lecturer/account', label: 'Account', icon: '🔒' },
];

function courseNavItems(courseId) {
  const base = `/lecturer/courses/${courseId}`;
  return [
    { path: '/lecturer', label: '← Dashboard', icon: '↩️', divider: true },
    { path: base, label: 'Course Overview', icon: '🏠', end: true },
    { path: `${base}/roster`, label: 'Roster', icon: '👥' },
    { path: `${base}/assessments`, label: 'Assessments', icon: '🧾' },
    { path: `${base}/grades`, label: 'Grades', icon: '🎓' },
    { path: `${base}/attendance`, label: 'Attendance', icon: '✅' },
  ];
}

// The sidebar itself swaps to this course's nav while a course is open,
// replacing the general dashboard items entirely - not just an extra tab
// strip alongside an unchanged sidebar.
export default function LecturerLayout() {
  const match = useMatch('/lecturer/courses/:courseId/*');
  const navItems = match ? courseNavItems(match.params.courseId) : GENERAL_NAV_ITEMS;

  return <AppShell navItems={navItems} />;
}
