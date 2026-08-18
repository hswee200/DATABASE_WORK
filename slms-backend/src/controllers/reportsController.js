const { withRole } = require('../db');
const { canReadLecturer } = require('../auth/access');

// Admin-only oversight views - no per-user scoping, Admin sees everything
// (see sql/08_add_reporting_views.sql for the view definitions/grants).
async function getAdminReports(req, res, next) {
  try {
    const result = await withRole(req.user.dbRole, async (conn) => {
      const [courseScoreRanking] = await conn.execute(
        'SELECT * FROM vw_course_score_ranking ORDER BY CourseID, RankInCourse'
      );
      const [lateSubmissions] = await conn.execute(
        'SELECT * FROM vw_late_submissions ORDER BY CourseID, LatenessRankInCourse'
      );
      const [neverAbsentStudents] = await conn.execute(
        'SELECT * FROM vw_never_absent_students ORDER BY StudentID'
      );
      const [coursesWithoutAssessments] = await conn.execute(
        'SELECT * FROM vw_courses_without_assessments ORDER BY CourseID'
      );
      const [courseEnrollmentRanking] = await conn.execute(
        'SELECT * FROM vw_course_enrollment_ranking ORDER BY EnrollmentRank'
      );
      const [coursePerformanceRanking] = await conn.execute(
        'SELECT * FROM vw_course_performance_ranking ORDER BY LowPerformanceRank'
      );
      return {
        courseScoreRanking,
        lateSubmissions,
        neverAbsentStudents,
        coursesWithoutAssessments,
        courseEnrollmentRanking,
        coursePerformanceRanking,
      };
    });

    return res.json({
      courseScoreRanking: result.courseScoreRanking.map((r) => ({
        courseId: r.CourseID,
        courseName: r.CourseName,
        studentId: r.StudentID,
        firstName: r.F_Name,
        lastName: r.L_Name,
        avgScore: r.AvgScore === null ? null : Number(r.AvgScore),
        rankInCourse: r.RankInCourse,
      })),
      lateSubmissions: result.lateSubmissions.map((r) => ({
        studentId: r.StudentID,
        firstName: r.F_Name,
        lastName: r.L_Name,
        courseId: r.CourseID,
        courseName: r.CourseName,
        assessmentName: r.AssessmentName,
        dueDate: r.DueDate,
        submissionDate: r.SubmissionDate,
        daysLate: r.DaysLate,
        latenessRankInCourse: r.LatenessRankInCourse,
      })),
      neverAbsentStudents: result.neverAbsentStudents.map((r) => ({
        studentId: r.StudentID,
        firstName: r.F_Name,
        lastName: r.L_Name,
      })),
      coursesWithoutAssessments: result.coursesWithoutAssessments.map((r) => ({
        courseId: r.CourseID,
        courseName: r.CourseName,
        courseCode: r.CourseCode,
      })),
      courseEnrollmentRanking: result.courseEnrollmentRanking.map((r) => ({
        courseId: r.CourseID,
        courseName: r.CourseName,
        enrolledStudents: Number(r.EnrolledStudents),
        enrollmentRank: r.EnrollmentRank,
      })),
      coursePerformanceRanking: result.coursePerformanceRanking.map((r) => ({
        courseId: r.CourseID,
        courseName: r.CourseName,
        avgScorePct: r.AvgScorePct === null ? null : Number(r.AvgScorePct),
        lowPerformanceRank: r.LowPerformanceRank,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

// Lecturer-only, own courses only. vw_course_score_ranking and
// vw_late_submissions carry no LecturerID column (they're general
// reporting views, also granted to admin_role), so ownership is applied by
// filtering to CourseID IN (this lecturer's own courses) rather than a
// WHERE LecturerID = ? the view can't express.
async function getLecturerReports(req, res, next) {
  try {
    const { lecturerId } = req.params;

    if (!canReadLecturer(req.user, lecturerId)) {
      return res.status(403).json({ error: 'Not permitted to view these reports.' });
    }

    const result = await withRole(req.user.dbRole, async (conn) => {
      const ownCourses = 'SELECT CourseID FROM COURSE WHERE LecturerID = ?';

      const [courseScoreRanking] = await conn.execute(
        `SELECT * FROM vw_course_score_ranking WHERE CourseID IN (${ownCourses}) ORDER BY CourseID, RankInCourse`,
        [lecturerId]
      );
      const [lateSubmissions] = await conn.execute(
        `SELECT * FROM vw_late_submissions WHERE CourseID IN (${ownCourses}) ORDER BY CourseID, LatenessRankInCourse`,
        [lecturerId]
      );
      const [upcomingDeadlines] = await conn.execute(
        `SELECT * FROM vw_upcoming_deadlines_ranked WHERE CourseID IN (${ownCourses}) ORDER BY CourseID, DeadlineRankInCourse`,
        [lecturerId]
      );
      return { courseScoreRanking, lateSubmissions, upcomingDeadlines };
    });

    return res.json({
      courseScoreRanking: result.courseScoreRanking.map((r) => ({
        courseId: r.CourseID,
        courseName: r.CourseName,
        studentId: r.StudentID,
        firstName: r.F_Name,
        lastName: r.L_Name,
        avgScore: r.AvgScore === null ? null : Number(r.AvgScore),
        rankInCourse: r.RankInCourse,
      })),
      lateSubmissions: result.lateSubmissions.map((r) => ({
        studentId: r.StudentID,
        firstName: r.F_Name,
        lastName: r.L_Name,
        courseId: r.CourseID,
        courseName: r.CourseName,
        assessmentName: r.AssessmentName,
        dueDate: r.DueDate,
        submissionDate: r.SubmissionDate,
        daysLate: r.DaysLate,
        latenessRankInCourse: r.LatenessRankInCourse,
      })),
      upcomingDeadlines: result.upcomingDeadlines.map((r) => ({
        courseId: r.CourseID,
        courseName: r.CourseName,
        assessmentName: r.AssessmentName,
        dueDate: r.DueDate,
        daysRemaining: r.DaysRemaining,
        deadlineRankInCourse: r.DeadlineRankInCourse,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getAdminReports, getLecturerReports };
