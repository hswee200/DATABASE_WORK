-- SLMS representative SQL queries
-- Run after create_database.sql, create_tables.sql, and insert_data.sql.

USE slms;

-- 1. JOIN: list users with their application roles.
SELECT u.UserID, u.Username, u.Email, r.RoleName, u.IsActive
FROM APP_USER AS u
JOIN User_Role AS r ON r.RoleID = u.RoleID
ORDER BY r.RoleName, u.Username;

-- 2. JOIN: list each course, its lecturer, and academic term.
SELECT c.CourseCode, c.CourseName, c.CreditHours,
       l.LecturerID, l.F_Name AS LecturerFirstName, l.L_Name AS LecturerLastName,
       s.SemesterName, s.AcademicYear
FROM COURSE AS c
JOIN Lecturer AS l ON l.LecturerID = c.LecturerID
JOIN SEMESTER AS s ON s.SemesterID = c.SemesterID
ORDER BY s.AcademicYear, s.SemesterName, c.CourseCode;

-- 3. Aggregate: enrolment totals by course.
SELECT c.CourseID, c.CourseCode, c.CourseName,
       COUNT(e.StudentID) AS EnrolledStudents
FROM COURSE AS c
LEFT JOIN ENROLLMENT AS e ON e.CourseID = c.CourseID
GROUP BY c.CourseID, c.CourseCode, c.CourseName
ORDER BY EnrolledStudents DESC, c.CourseCode;

-- 4. Subquery: students whose average score is below their course average.
SELECT x.CourseID, x.CourseName, x.StudentID, x.F_Name, x.L_Name,
       x.StudentAverage, x.CourseAverage
FROM (
  SELECT c.CourseID, c.CourseName, st.StudentID, st.F_Name, st.L_Name,
         AVG(sub.Score) AS StudentAverage,
         AVG(AVG(sub.Score)) OVER (PARTITION BY c.CourseID) AS CourseAverage
  FROM SUBMISSION AS sub
  JOIN ASSESSMENT AS a ON a.AssessmentID = sub.AssessmentID
  JOIN COURSE AS c ON c.CourseID = a.CourseID
  JOIN STUDENT AS st ON st.StudentID = sub.StudentID
  WHERE sub.IsActive = TRUE AND sub.Score IS NOT NULL
  GROUP BY c.CourseID, c.CourseName, st.StudentID, st.F_Name, st.L_Name
) AS x
WHERE x.StudentAverage < x.CourseAverage
ORDER BY x.CourseID, x.StudentAverage;

-- 5. View: retrieve calculated final grades and grade points.
SELECT StudentID, SemesterName, AcademicYear, CourseID, CourseName,
       FinalGradePercent, LetterGrade, GradePoint
FROM vw_student_final_grades
ORDER BY StudentID, AcademicYear, SemesterName, CourseID;

-- 6. View: retrieve the current ungraded-submission queue.
SELECT LecturerID, CourseName, AssessmentName, F_Name, L_Name,
       SubmissionID, SubmissionDate, UngradedCountForThisAssessment
FROM vw_ungraded_submissions
ORDER BY LecturerID, SubmissionDate, SubmissionID;
