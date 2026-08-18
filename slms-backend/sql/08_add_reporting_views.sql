-- Nine reporting views (query 5, lecturer workload, was skipped - it's a
-- duplicate of vw_lecturer_load, which already exists and is already wired
-- into the frontend). Views 8 and 9 have no hardcoded ID filter - views
-- can't take parameters, so the ID is exposed as an output column and every
-- caller filters from the application layer, same as every other view in
-- this schema (see studentsController.js/lecturersController.js for the
-- existing pattern).
--
-- Must run as root@localhost, which is also each view's DEFINER.

USE slms;

-- 1. Course score ranking
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_course_score_ranking AS
SELECT
    c.CourseID, c.CourseName, st.StudentID, st.F_Name, st.L_Name,
    ROUND(AVG(sub.Score), 2) AS AvgScore,
    RANK() OVER (PARTITION BY c.CourseID ORDER BY AVG(sub.Score) DESC) AS RankInCourse
FROM SUBMISSION sub
JOIN ASSESSMENT a ON sub.AssessmentID = a.AssessmentID
JOIN COURSE c ON a.CourseID = c.CourseID
JOIN STUDENT st ON sub.StudentID = st.StudentID
JOIN ENROLLMENT e ON e.StudentID = st.StudentID AND e.CourseID = c.CourseID
WHERE sub.IsActive = TRUE
GROUP BY c.CourseID, c.CourseName, st.StudentID, st.F_Name, st.L_Name;

-- 2. Late submissions
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_late_submissions AS
SELECT
    st.StudentID, st.F_Name, st.L_Name, c.CourseID, c.CourseName,
    a.AssessmentName, a.DueDate, sub.SubmissionDate,
    DATEDIFF(sub.SubmissionDate, a.DueDate) AS DaysLate,
    RANK() OVER (PARTITION BY c.CourseID ORDER BY DATEDIFF(sub.SubmissionDate, a.DueDate) DESC) AS LatenessRankInCourse
FROM SUBMISSION sub
JOIN ASSESSMENT a ON sub.AssessmentID = a.AssessmentID
JOIN COURSE c ON a.CourseID = c.CourseID
JOIN STUDENT st ON sub.StudentID = st.StudentID
WHERE sub.IsActive = TRUE AND sub.SubmissionDate > a.DueDate;

-- 3. Students never marked absent
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_never_absent_students AS
SELECT st.StudentID, st.F_Name, st.L_Name
FROM STUDENT st
WHERE EXISTS (SELECT 1 FROM ATTENDANCE att WHERE att.StudentID = st.StudentID)
  AND NOT EXISTS (SELECT 1 FROM ATTENDANCE att WHERE att.StudentID = st.StudentID AND att.Status = 'Absent');

-- 4. Courses with zero assessments
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_courses_without_assessments AS
SELECT DISTINCT c.CourseID, c.CourseName, c.CourseCode
FROM COURSE c
LEFT JOIN ASSESSMENT a ON c.CourseID = a.CourseID
WHERE a.AssessmentID IS NULL;

-- 6. Course enrollment ranking
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_course_enrollment_ranking AS
SELECT
    c.CourseID, c.CourseName, COUNT(e.StudentID) AS EnrolledStudents,
    RANK() OVER (ORDER BY COUNT(e.StudentID) DESC) AS EnrollmentRank
FROM COURSE c
JOIN ENROLLMENT e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.CourseName;

-- 7. Upcoming deadlines, ranked
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_upcoming_deadlines_ranked AS
SELECT
    c.CourseID, c.CourseName, a.AssessmentName, a.DueDate,
    DATEDIFF(a.DueDate, CURRENT_DATE) AS DaysRemaining,
    RANK() OVER (PARTITION BY a.CourseID ORDER BY a.DueDate ASC) AS DeadlineRankInCourse
FROM ASSESSMENT a
JOIN COURSE c ON a.CourseID = c.CourseID
WHERE a.DueDate >= CURRENT_DATE;

-- 8. Below class average (StudentID exposed as an output column - filter
-- from the app: SELECT * FROM vw_below_class_average WHERE StudentID = ?
-- AND StudentAvg < ClassAvg)
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_below_class_average AS
SELECT y.CourseID, y.CourseName, y.StudentID, y.F_Name, y.L_Name, y.StudentAvg,
       AVG(y.StudentAvg) OVER (PARTITION BY y.CourseID) AS ClassAvg
FROM (
    SELECT c.CourseID, c.CourseName, st.StudentID, st.F_Name, st.L_Name, AVG(sub.Score) AS StudentAvg
    FROM SUBMISSION sub
    JOIN ASSESSMENT a ON sub.AssessmentID = a.AssessmentID
    JOIN COURSE c ON a.CourseID = c.CourseID
    JOIN STUDENT st ON sub.StudentID = st.StudentID
    WHERE sub.IsActive = TRUE
    GROUP BY c.CourseID, c.CourseName, st.StudentID, st.F_Name, st.L_Name
) y;

-- 9. Ungraded submissions (LecturerID exposed as an output column - filter
-- from the app: SELECT * FROM vw_ungraded_submissions WHERE LecturerID = ?)
-- This is the data source for the Grade Submission screen, replacing its
-- manual Submission ID field entirely.
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_ungraded_submissions AS
SELECT
    c.LecturerID, c.CourseName, a.AssessmentName, st.F_Name, st.L_Name,
    sub.SubmissionID, sub.SubmissionDate,
    COUNT(*) OVER (PARTITION BY sub.AssessmentID) AS UngradedCountForThisAssessment
FROM SUBMISSION sub
JOIN ASSESSMENT a ON sub.AssessmentID = a.AssessmentID
JOIN COURSE c ON a.CourseID = c.CourseID
JOIN STUDENT st ON sub.StudentID = st.StudentID
WHERE sub.IsActive = TRUE AND sub.Score IS NULL;

-- 10. Course performance ranking (lowest first)
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_course_performance_ranking AS
SELECT
    c.CourseID, c.CourseName,
    ROUND(AVG(sub.Score * 100.0 / a.MaxScore), 1) AS AvgScorePct,
    RANK() OVER (ORDER BY AVG(sub.Score * 100.0 / a.MaxScore) ASC) AS LowPerformanceRank
FROM SUBMISSION sub
JOIN ASSESSMENT a ON sub.AssessmentID = a.AssessmentID
JOIN COURSE c ON a.CourseID = c.CourseID
WHERE sub.IsActive = TRUE
GROUP BY c.CourseID, c.CourseName;

-- Access grants, per the separation-of-duties rules already established
-- (see 03_grant_execute.sql and canModifyCourseContent/canReadCourse):

-- Oversight/reporting views: read-only, fine for Admin
GRANT SELECT ON slms.vw_course_score_ranking TO admin_role;
GRANT SELECT ON slms.vw_late_submissions TO admin_role;
GRANT SELECT ON slms.vw_never_absent_students TO admin_role;
GRANT SELECT ON slms.vw_courses_without_assessments TO admin_role;
GRANT SELECT ON slms.vw_course_enrollment_ranking TO admin_role;
GRANT SELECT ON slms.vw_course_performance_ranking TO admin_role;

-- Lecturer-relevant views: their own course scope
GRANT SELECT ON slms.vw_course_score_ranking TO lecturer_role;
GRANT SELECT ON slms.vw_late_submissions TO lecturer_role;
GRANT SELECT ON slms.vw_upcoming_deadlines_ranked TO lecturer_role;
GRANT SELECT ON slms.vw_ungraded_submissions TO lecturer_role;

-- Student-relevant: their own record only
GRANT SELECT ON slms.vw_upcoming_deadlines_ranked TO student_role;
GRANT SELECT ON slms.vw_below_class_average TO student_role;

FLUSH PRIVILEGES;
