import { useMatch } from 'react-router-dom';
import AppShell from '../../components/AppShell';

// No grading, attendance-marking, or assessment-editing here on purpose:
// Admin represents the registrar function (accounts, enrolment, scheduling,
// oversight), not the instructor function. Those academic-judgment actions
// are Lecturer-only - see canModifyCourseContent in the backend.
const GENERAL_NAV_ITEMS = [
  { path: '/admin', label: 'Overview', icon: '🏠', end: true },
  { path: '/admin/courses', label: 'Courses', icon: '📚' },
  { path: '/admin/transcripts', label: 'Transcripts', icon: '📄' },
  { path: '/admin/load', label: 'Lecturer Load', icon: '📊' },
  { path: '/admin/reports', label: 'Reports', icon: '📈' },
  { path: '/admin/create-user', label: 'Create User', icon: '➕' },
  { path: '/admin/deactivate-user', label: 'Deactivate User', icon: '🚫' },
  { path: '/admin/reactivate-user', label: 'Reactivate User', icon: '✅' },
  { path: '/admin/corrections', label: 'Corrections', icon: '🛠️' },
  { path: '/admin/account', label: 'Account', icon: '🔒' },
];

function courseNavItems(courseId) {
  const base = `/admin/courses/${courseId}`;
  return [
    { path: '/admin/courses', label: '← Courses', icon: '↩️', divider: true },
    { path: base, label: 'Course Overview', icon: '🏠', end: true },
    { path: `${base}/roster`, label: 'Roster', icon: '👥' },
    { path: `${base}/reassign`, label: 'Reassign Lecturer', icon: '🔁' },
    { path: `${base}/timetable`, label: 'Timetable', icon: '🗓️' },
  ];
}

// The sidebar itself swaps to this course's nav while a course is open,
// replacing the general dashboard items entirely - not just an extra tab
// strip alongside an unchanged sidebar.
export default function AdminLayout() {
  const match = useMatch('/admin/courses/:courseId/*');
  const navItems = match ? courseNavItems(match.params.courseId) : GENERAL_NAV_ITEMS;

  return <AppShell navItems={navItems} />;
}
