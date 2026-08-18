import { useMatch } from 'react-router-dom';
import AppShell from '../../components/AppShell';

const GENERAL_NAV_ITEMS = [
  { path: '/student', label: 'Overview', icon: '🏠', end: true },
  { path: '/student/transcript', label: 'Transcript', icon: '📄' },
  { path: '/student/timetable', label: 'Timetable', icon: '🗓️' },
  { path: '/student/attendance', label: 'Attendance', icon: '✅' },
  { path: '/student/assessments', label: 'Assessments', icon: '📝' },
  { path: '/student/account', label: 'Account', icon: '🔒' },
];

function courseNavItems(courseId) {
  const base = `/student/courses/${courseId}`;
  return [
    { path: '/student', label: '← Dashboard', icon: '↩️', divider: true },
    { path: base, label: 'Course Overview', icon: '🏠', end: true },
    { path: `${base}/assessments`, label: 'Assessments', icon: '📝' },
    { path: `${base}/grade`, label: 'Grade', icon: '🎓' },
    { path: `${base}/attendance`, label: 'Attendance', icon: '✅' },
    { path: `${base}/roster`, label: 'Roster', icon: '👥' },
  ];
}

// The sidebar itself swaps to this course's nav while a course is open,
// replacing the general dashboard items entirely - not just an extra tab
// strip alongside an unchanged sidebar.
export default function StudentLayout() {
  const match = useMatch('/student/courses/:courseId/*');
  const navItems = match ? courseNavItems(match.params.courseId) : GENERAL_NAV_ITEMS;

  return <AppShell navItems={navItems} />;
}
