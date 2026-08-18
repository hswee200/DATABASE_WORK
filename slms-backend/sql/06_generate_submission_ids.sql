-- Submit/Resubmit made the student invent and type a SubmissionID, exposing a
-- raw database ID the same way this build has avoided everywhere else. This
-- moves ID generation server-side, mirroring sp_enroll_student's pattern for
-- EnrollmentID (SLMS.sql:321-350): MAX(CAST(SUBSTRING(...) AS UNSIGNED))+1,
-- then CONCAT+LPAD. SUBMISSION.SubmissionID seed values are all 'SUB' + 3
-- digits, so the same prefix/width applies.
--
-- MariaDB has no ALTER PROCEDURE for the body, so this is DROP + CREATE.
-- Must run as root@localhost, which is also the procedure's DEFINER.

USE SLMS;

DELIMITER //

DROP PROCEDURE IF EXISTS sp_submit_assessment //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_submit_assessment(
    IN p_StudentID VARCHAR(20),
    IN p_AssessmentID VARCHAR(20)
)
BEGIN
    DECLARE next_num INT;
    DECLARE next_id VARCHAR(20);

    IF EXISTS (
        SELECT 1 FROM SUBMISSION
        WHERE StudentID = p_StudentID
          AND AssessmentID = p_AssessmentID
          AND IsActive = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Already submitted for this assessment — use resubmit instead.';
    ELSE
        SELECT IFNULL(MAX(CAST(SUBSTRING(SubmissionID, 4) AS UNSIGNED)), 0) + 1
        INTO next_num
        FROM SUBMISSION;

        SET next_id = CONCAT('SUB', LPAD(next_num, 3, '0'));

        INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)
        VALUES (next_id, p_AssessmentID, p_StudentID, CURDATE(), NULL, TRUE);
    END IF;
END //

DROP PROCEDURE IF EXISTS sp_resubmit_assessment //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_resubmit_assessment(
    IN p_StudentID VARCHAR(20),
    IN p_AssessmentID VARCHAR(20)
)
BEGIN
    DECLARE next_num INT;
    DECLARE next_id VARCHAR(20);

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

    SELECT IFNULL(MAX(CAST(SUBSTRING(SubmissionID, 4) AS UNSIGNED)), 0) + 1
    INTO next_num
    FROM SUBMISSION;

    SET next_id = CONCAT('SUB', LPAD(next_num, 3, '0'));

    INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)
    VALUES (next_id, p_AssessmentID, p_StudentID, CURDATE(), NULL, TRUE);

    COMMIT;
END //

DELIMITER ;

-- DROP PROCEDURE also drops the routine's privileges, so the grants from
-- 05_fix_submission_lifecycle.sql are gone by this point.
GRANT EXECUTE ON PROCEDURE SLMS.sp_submit_assessment   TO student_role;
GRANT EXECUTE ON PROCEDURE SLMS.sp_resubmit_assessment TO student_role;

FLUSH PRIVILEGES;
