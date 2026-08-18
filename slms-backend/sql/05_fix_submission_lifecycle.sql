-- submissionsController.js calls sp_submit_assessment / sp_resubmit_assessment
-- and queries SUBMISSION.IsActive, but none of that existed in the schema --
-- Submit/Resubmit failed outright. This adds the missing column and
-- procedures, and makes every reader of SUBMISSION (grading, transcript
-- averages, the student assessment-status view) ignore superseded rows so a
-- resubmit can never be graded twice or double-counted.
--
-- MariaDB has no ALTER PROCEDURE for the body, so procedure changes are
-- DROP + CREATE. Must run as root@localhost, which is also the DEFINER.

USE SLMS;

ALTER TABLE SUBMISSION ADD COLUMN IsActive BOOLEAN NOT NULL DEFAULT TRUE;

DELIMITER //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_submit_assessment(
    IN p_StudentID VARCHAR(20),
    IN p_AssessmentID VARCHAR(20),
    IN p_SubmissionID VARCHAR(20)
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM SUBMISSION
        WHERE StudentID = p_StudentID
          AND AssessmentID = p_AssessmentID
          AND IsActive = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Already submitted for this assessment — use resubmit instead.';
    ELSE
        INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)
        VALUES (p_SubmissionID, p_AssessmentID, p_StudentID, CURDATE(), NULL, TRUE);
    END IF;
END //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_resubmit_assessment(
    IN p_StudentID VARCHAR(20),
    IN p_AssessmentID VARCHAR(20),
    IN p_NewSubmissionID VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM SUBMISSION
        WHERE StudentID = p_StudentID
          AND AssessmentID = p_AssessmentID
          AND IsActive = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No existing submission to resubmit — submit first.';
    END IF;

    START TRANSACTION;

    UPDATE SUBMISSION
    SET IsActive = FALSE
    WHERE StudentID = p_StudentID
      AND AssessmentID = p_AssessmentID
      AND IsActive = TRUE;

    INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)
    VALUES (p_NewSubmissionID, p_AssessmentID, p_StudentID, CURDATE(), NULL, TRUE);

    COMMIT;
END //

DROP PROCEDURE IF EXISTS sp_record_grade //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_record_grade(
    IN p_SubmissionID VARCHAR(20),
    IN p_Score DECIMAL(5,2)
)
BEGIN
    DECLARE v_AssessmentID VARCHAR(20);
    DECLARE v_MaxScore DECIMAL(5,2);

    SELECT AssessmentID
    INTO v_AssessmentID
    FROM SUBMISSION
    WHERE SubmissionID = p_SubmissionID
      AND IsActive = TRUE;

    SELECT MaxScore
    INTO v_MaxScore
    FROM ASSESSMENT
    WHERE AssessmentID = v_AssessmentID;

    IF p_Score > v_MaxScore THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Score exceeds the maximum allowed for this assessment.';
    ELSEIF p_Score < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Score cannot be negative.';
    ELSE
        UPDATE SUBMISSION
        SET Score = p_Score
        WHERE SubmissionID = p_SubmissionID
          AND IsActive = TRUE;
    END IF;
END //

DELIMITER ;

-- Superseded submissions must drop out of a student's final-grade average,
-- not just out of grading — otherwise a resubmit's old score keeps pulling
-- the transcript average even after being replaced.
CREATE OR REPLACE VIEW VW_STUDENT_FINAL_GRADES AS
SELECT
    st.StudentID,
    st.F_Name,
    st.L_Name,
    s.SemesterName,
    s.AcademicYear,
    c.CourseID,
    c.CourseName,
    ROUND(AVG(sub.Score / a.MaxScore * 100), 2) AS FinalGradePercent
FROM SUBMISSION sub
JOIN ASSESSMENT a
    ON sub.AssessmentID = a.AssessmentID
JOIN COURSE c
    ON a.CourseID = c.CourseID
JOIN SEMESTER s
    ON c.SemesterID = s.SemesterID
JOIN STUDENT st
    ON sub.StudentID = st.StudentID
WHERE sub.IsActive = TRUE
GROUP BY
    st.StudentID,
    st.F_Name,
    st.L_Name,
    s.SemesterName,
    s.AcademicYear,
    c.CourseID,
    c.CourseName;

-- The IsActive filter goes in the LEFT JOIN's ON clause, not a WHERE, so an
-- assessment with no active submission still appears (SubmissionID NULL) --
-- a WHERE here would silently drop not-yet-submitted assessments, and
-- without any filter a resubmit would produce two rows per assessment (old
-- inactive + new active) once sp_resubmit_assessment starts working.
CREATE OR REPLACE VIEW VW_ASSESSMENT_STATUS AS
SELECT
    e.StudentID,
    a.AssessmentID,
    a.AssessmentName,
    a.CourseID,
    a.DueDate,
    sub.SubmissionID,
    CASE
        WHEN sub.SubmissionID IS NOT NULL THEN 'Submitted'
        WHEN a.DueDate < CURDATE() THEN 'Past-Due'
        ELSE 'Upcoming'
    END AS Status
FROM ENROLLMENT e
JOIN ASSESSMENT a ON e.CourseID = a.CourseID
LEFT JOIN SUBMISSION sub
    ON sub.AssessmentID = a.AssessmentID
   AND sub.StudentID = e.StudentID
   AND sub.IsActive = TRUE;

GRANT EXECUTE ON PROCEDURE SLMS.sp_submit_assessment   TO student_role;
GRANT EXECUTE ON PROCEDURE SLMS.sp_resubmit_assessment TO student_role;

-- DROP PROCEDURE also drops the routine's privileges, so the grant from
-- 03_grant_execute.sql is gone by this point.
GRANT EXECUTE ON PROCEDURE SLMS.sp_record_grade TO lecturer_role;

FLUSH PRIVILEGES;
