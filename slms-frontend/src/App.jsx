import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './auth/AuthContext';
import ProtectedRoute from './auth/ProtectedRoute';
import LoginPage from './pages/LoginPage';

import StudentLayout from './pages/student/StudentLayout';
import StudentOverview from './pages/student/StudentOverview';
import TranscriptSection from './pages/student/TranscriptSection';
import TimetableSection from './pages/student/TimetableSection';
import AttendanceSection from './pages/student/AttendanceSection';
import AssessmentBoard from './pages/student/AssessmentBoard';
import StudentCourseLayout from './pages/student/CourseLayout';
import StudentCourseOverview from './pages/student/course/CourseOverview';
import StudentCourseGrade from './pages/student/course/CourseGrade';
import StudentCourseAttendance from './pages/student/course/CourseAttendance';
import StudentCourseAssessments from './pages/student/course/CourseAssessments';
import StudentCourseRoster from './pages/student/course/CourseRoster';

import LecturerLayout from './pages/lecturer/LecturerLayout';
import LecturerOverview from './pages/lecturer/LecturerOverview';
import LecturerTimetableSection from './pages/lecturer/LecturerTimetableSection';
import WorkloadSection from './pages/lecturer/WorkloadSection';
import GradeSubmissionsSection from './pages/lecturer/GradeSubmissionsSection';
import LecturerReportsSection from './pages/lecturer/ReportsSection';
import LecturerCourseLayout from './pages/lecturer/CourseLayout';
import LecturerCourseOverview from './pages/lecturer/course/CourseOverview';
import LecturerCourseRoster from './pages/lecturer/course/CourseRoster';
import LecturerCourseAssessments from './pages/lecturer/course/CourseAssessments';
import LecturerCourseGrades from './pages/lecturer/course/CourseGrades';
import LecturerCourseAttendance from './pages/lecturer/course/CourseAttendance';

import AdminLayout from './pages/admin/AdminLayout';
import AdminOverview from './pages/admin/AdminOverview';
import AdminCoursesSection from './pages/admin/AdminCoursesSection';
import TranscriptLookupSection from './pages/admin/TranscriptLookupSection';
import AllLoadSection from './pages/admin/AllLoadSection';
import CreateUserSection from './pages/admin/CreateUserSection';
import DeactivateUserSection from './pages/admin/DeactivateUserSection';
import ReactivateUserSection from './pages/admin/ReactivateUserSection';
import CorrectionsSection from './pages/admin/CorrectionsSection';
import AdminReportsSection from './pages/admin/ReportsSection';
import AdminCourseLayout from './pages/admin/CourseLayout';
import AdminCourseOverview from './pages/admin/course/CourseOverview';
import AdminCourseRoster from './pages/admin/course/CourseRoster';
import AdminCourseReassign from './pages/admin/course/CourseReassign';
import AdminCourseTimetable from './pages/admin/course/CourseTimetable';

import ChangePasswordSection from './pages/shared/ChangePasswordSection';

function RootRedirect() {
  const { isAuthenticated, user } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <Navigate to={`/${user.roleName.toLowerCase()}`} replace />;
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />

          <Route
            path="/student"
            element={
              <ProtectedRoute allowedRole="Student">
                <StudentLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<StudentOverview />} />
            <Route path="transcript" element={<TranscriptSection />} />
            <Route path="timetable" element={<TimetableSection />} />
            <Route path="attendance" element={<AttendanceSection />} />
            <Route path="assessments" element={<AssessmentBoard />} />
            <Route path="courses/:courseId" element={<StudentCourseLayout />}>
              <Route index element={<StudentCourseOverview />} />
              <Route path="assessments" element={<StudentCourseAssessments />} />
              <Route path="grade" element={<StudentCourseGrade />} />
              <Route path="attendance" element={<StudentCourseAttendance />} />
              <Route path="roster" element={<StudentCourseRoster />} />
            </Route>
            <Route path="account" element={<ChangePasswordSection />} />
          </Route>

          <Route
            path="/lecturer"
            element={
              <ProtectedRoute allowedRole="Lecturer">
                <LecturerLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<LecturerOverview />} />
            <Route path="timetable" element={<LecturerTimetableSection />} />
            <Route path="workload" element={<WorkloadSection />} />
            <Route path="grade" element={<GradeSubmissionsSection />} />
            <Route path="reports" element={<LecturerReportsSection />} />
            <Route path="courses/:courseId" element={<LecturerCourseLayout />}>
              <Route index element={<LecturerCourseOverview />} />
              <Route path="roster" element={<LecturerCourseRoster />} />
              <Route path="assessments" element={<LecturerCourseAssessments />} />
              <Route path="grades" element={<LecturerCourseGrades />} />
              <Route path="attendance" element={<LecturerCourseAttendance />} />
            </Route>
            <Route path="account" element={<ChangePasswordSection />} />
          </Route>

          <Route
            path="/admin"
            element={
              <ProtectedRoute allowedRole="Admin">
                <AdminLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<AdminOverview />} />
            <Route path="courses" element={<AdminCoursesSection />} />
            <Route path="courses/:courseId" element={<AdminCourseLayout />}>
              <Route index element={<AdminCourseOverview />} />
              <Route path="roster" element={<AdminCourseRoster />} />
              <Route path="reassign" element={<AdminCourseReassign />} />
              <Route path="timetable" element={<AdminCourseTimetable />} />
            </Route>
            <Route path="transcripts" element={<TranscriptLookupSection />} />
            <Route path="load" element={<AllLoadSection />} />
            <Route path="reports" element={<AdminReportsSection />} />
            <Route path="create-user" element={<CreateUserSection />} />
            <Route path="deactivate-user" element={<DeactivateUserSection />} />
            <Route path="reactivate-user" element={<ReactivateUserSection />} />
            <Route path="corrections" element={<CorrectionsSection />} />
            <Route path="account" element={<ChangePasswordSection />} />
          </Route>

          <Route path="/" element={<RootRedirect />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
