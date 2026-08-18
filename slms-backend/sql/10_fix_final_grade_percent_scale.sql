-- vw_student_final_grades computed FinalGradePercent as
-- SUM(Score/MaxScore*Weight)/SUM(Weight) - that's a weighted average of a
-- 0-1 fraction, not a percentage, so it came out as e.g. 0.63 instead of
-- 63.00. Missing the *100 that converts the fraction to a percent before
-- the weighted average. Caught via vw_student_gpa returning 0.00 GPA for
-- every student (LetterGrade bands are all >=50/60/70/80/90, so a value
-- under 1 always fell into 'F' / GradePoint 0).
--
-- Must run as root@localhost.

USE slms;

CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_student_final_grades AS
SELECT
    x.StudentID, x.F_Name, x.L_Name, x.SemesterID, x.SemesterName, x.AcademicYear,
    x.CourseID, x.CourseName, x.CreditHours, x.FinalGradePercent,
    CASE
        WHEN x.FinalGradePercent >= 90 THEN 'A+'
        WHEN x.FinalGradePercent >= 80 THEN 'A'
        WHEN x.FinalGradePercent >= 70 THEN 'B'
        WHEN x.FinalGradePercent >= 60 THEN 'C'
        WHEN x.FinalGradePercent >= 50 THEN 'D'
        ELSE 'F'
    END AS LetterGrade,
    CASE
        WHEN x.FinalGradePercent >= 80 THEN 4.0
        WHEN x.FinalGradePercent >= 70 THEN 3.0
        WHEN x.FinalGradePercent >= 60 THEN 2.0
        WHEN x.FinalGradePercent >= 50 THEN 1.0
        ELSE 0.0
    END AS GradePoint
FROM (
    SELECT
        g.StudentID, g.F_Name, g.L_Name, c.SemesterID, s.SemesterName, s.AcademicYear,
        c.CourseID, c.CourseName, c.CreditHours,
        ROUND(SUM(g.Score / g.MaxScore * g.Weight) / SUM(g.Weight) * 100, 2) AS FinalGradePercent
    FROM vw_course_grades g
    JOIN COURSE c ON c.CourseID = g.CourseID
    JOIN SEMESTER s ON c.SemesterID = s.SemesterID
    WHERE g.Score IS NOT NULL
    GROUP BY g.StudentID, g.F_Name, g.L_Name, c.SemesterID, s.SemesterName, s.AcademicYear, c.CourseID, c.CourseName, c.CreditHours
) x;

GRANT SELECT ON slms.vw_student_final_grades TO student_role;

FLUSH PRIVILEGES;
