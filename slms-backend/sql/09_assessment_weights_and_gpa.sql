-- Adds assessment weighting (Midsem 20% / Final 40% / Regular splits the
-- rest evenly), a per-course grades view showing every assessment (graded
-- or not) with its weight, and GPA/CGPA on a standard 4.0 scale.
--
-- MariaDB has no ALTER PROCEDURE for the body, so procedure changes are
-- DROP + CREATE. Must run as root@localhost, which is also the DEFINER for
-- every object here.

USE slms;

ALTER TABLE ASSESSMENT
  ADD COLUMN AssessmentCategory ENUM('Regular','Midsem','Final') NOT NULL DEFAULT 'Regular';

DELIMITER //

DROP PROCEDURE IF EXISTS sp_create_assessment //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_create_assessment(
    IN p_AssessmentID VARCHAR(20),
    IN p_CourseID VARCHAR(20),
    IN p_AssessmentType VARCHAR(50),
    IN p_AssessmentName VARCHAR(100),
    IN p_MaxScore DECIMAL(5,2),
    IN p_DueDate DATE,
    IN p_AssessmentCategory VARCHAR(10)
)
BEGIN
    DECLARE existing_count INT;

    SELECT COUNT(*) INTO existing_count FROM ASSESSMENT WHERE AssessmentID = p_AssessmentID;

    IF existing_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An assessment with that ID already exists.';
    ELSEIF p_AssessmentCategory = 'Midsem' AND EXISTS (
        SELECT 1 FROM ASSESSMENT WHERE CourseID = p_CourseID AND AssessmentCategory = 'Midsem'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This course already has a Midsem assessment.';
    ELSEIF p_AssessmentCategory = 'Final' AND EXISTS (
        SELECT 1 FROM ASSESSMENT WHERE CourseID = p_CourseID AND AssessmentCategory = 'Final'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This course already has a Final assessment.';
    ELSE
        INSERT INTO ASSESSMENT (AssessmentID, CourseID, AssessmentType, AssessmentName, MaxScore, DueDate, AssessmentCategory)
        VALUES (p_AssessmentID, p_CourseID, p_AssessmentType, p_AssessmentName, p_MaxScore, p_DueDate, p_AssessmentCategory);
    END IF;
END //

DELIMITER ;

-- One row per (StudentID, AssessmentID) for every assessment in a course the
-- student is enrolled in, whether submitted/graded or not (LEFT JOIN
-- SUBMISSION) - the "grades or not" requirement. Weight: Midsem=20,
-- Final=40, Regular splits whatever's left evenly among however many
-- Regular assessments the course has.
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_course_grades AS
SELECT
    e.StudentID, st.F_Name, st.L_Name, a.CourseID, a.AssessmentID, a.AssessmentName,
    a.AssessmentCategory, a.MaxScore, sub.Score, sub.SubmissionID,
    CASE a.AssessmentCategory
        WHEN 'Midsem' THEN 20
        WHEN 'Final' THEN 40
        ELSE (
            100
            - IF(EXISTS(SELECT 1 FROM ASSESSMENT a2 WHERE a2.CourseID = a.CourseID AND a2.AssessmentCategory = 'Midsem'), 20, 0)
            - IF(EXISTS(SELECT 1 FROM ASSESSMENT a2 WHERE a2.CourseID = a.CourseID AND a2.AssessmentCategory = 'Final'), 40, 0)
        ) / NULLIF((SELECT COUNT(*) FROM ASSESSMENT a3 WHERE a3.CourseID = a.CourseID AND a3.AssessmentCategory = 'Regular'), 0)
    END AS Weight
FROM ASSESSMENT a
JOIN ENROLLMENT e ON e.CourseID = a.CourseID
JOIN STUDENT st ON st.StudentID = e.StudentID
LEFT JOIN SUBMISSION sub
    ON sub.AssessmentID = a.AssessmentID
   AND sub.StudentID = e.StudentID
   AND sub.IsActive = TRUE;

-- Recreated on the same weighted logic as vw_course_grades (previously a
-- plain unweighted AVG over submitted work only) so the transcript and the
-- course Grades tab always agree. Adds CreditHours and a standard 4.0
-- GradePoint for GPA calculation - both new, this view had neither before.
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
        ROUND(SUM(g.Score / g.MaxScore * g.Weight) / SUM(g.Weight), 2) AS FinalGradePercent
    FROM vw_course_grades g
    JOIN COURSE c ON c.CourseID = g.CourseID
    JOIN SEMESTER s ON c.SemesterID = s.SemesterID
    WHERE g.Score IS NOT NULL
    GROUP BY g.StudentID, g.F_Name, g.L_Name, c.SemesterID, s.SemesterName, s.AcademicYear, c.CourseID, c.CourseName, c.CreditHours
) x;

-- SemesterGPA = credit-weighted average of that semester's courses.
-- CGPA = cumulative credit-weighted average of every semester up to and
-- including this one (window aggregate ordered by academic chronology).
CREATE OR REPLACE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_student_gpa AS
SELECT
    y.StudentID, y.SemesterID, y.SemesterName, y.AcademicYear, y.SemesterGPA,
    ROUND(
        SUM(y.QualityPoints) OVER (PARTITION BY y.StudentID ORDER BY y.AcademicYear, y.SemesterName)
        / SUM(y.SemesterCreditHours) OVER (PARTITION BY y.StudentID ORDER BY y.AcademicYear, y.SemesterName),
        2
    ) AS CGPA
FROM (
    SELECT
        StudentID, SemesterID, SemesterName, AcademicYear,
        ROUND(SUM(GradePoint * CreditHours) / SUM(CreditHours), 2) AS SemesterGPA,
        SUM(GradePoint * CreditHours) AS QualityPoints,
        SUM(CreditHours) AS SemesterCreditHours
    FROM vw_student_final_grades
    GROUP BY StudentID, SemesterID, SemesterName, AcademicYear
) y;

-- DROP PROCEDURE also drops the routine's privileges, so the grant from
-- 08_add_reporting_views.sql (and earlier) is gone by this point.
GRANT EXECUTE ON PROCEDURE slms.sp_create_assessment TO lecturer_role;

GRANT SELECT ON slms.vw_course_grades TO student_role;
GRANT SELECT ON slms.vw_course_grades TO lecturer_role;
GRANT SELECT ON slms.vw_student_gpa TO student_role;
GRANT SELECT ON slms.vw_student_gpa TO admin_role;

-- getTranscript now queries this view directly (rather than only through
-- sp_generate_transcript, which runs as DEFINER and didn't need a direct
-- grant) so it can also pull CreditHours/GradePoint, which the procedure's
-- fixed SELECT list doesn't return.
GRANT SELECT ON slms.vw_student_final_grades TO student_role;

FLUSH PRIVILEGES;
