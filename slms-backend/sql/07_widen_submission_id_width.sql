-- sp_submit_assessment/sp_resubmit_assessment generate SubmissionID via
-- MAX(numeric suffix)+1, then CONCAT('SUB', LPAD(next_num, 3, '0')). MariaDB's
-- LPAD TRUNCATES a string that's already >= the target width rather than
-- widening it, so once next_num reached 1000, LPAD(1000, 3, '0') produced
-- '100' instead of '1000' - colliding with the existing SUB100 row, and
-- every call after that kept recomputing the same colliding ID forever
-- (MAX() never advances past 999 once the collision starts, since '100' < 999
-- numerically). This is a deterministic, permanent failure once row count
-- crosses the width boundary, not a rare race.
--
-- Fixed by widening to 5 digits (room for 99,999 submissions - comfortably
-- outside this project's scope). Do NOT shrink this back down "to match
-- other IDs" - that reintroduces this exact bug. If you need to raise it
-- again, that's fine; if you need to lower it, read this comment first.
--
-- MariaDB has no ALTER PROCEDURE for the body, so this is DROP + CREATE.
-- Must run as root@localhost, which is also the procedure's DEFINER.

USE slms;

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

        -- 5-digit width (room to 99,999) - see file header. LPAD truncates
        -- rather than widens once next_num's digit count exceeds this, so
        -- this width IS the ceiling before IDs start colliding again.
        SET next_id = CONCAT('SUB', LPAD(next_num, 5, '0'));

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

    -- Same 5-digit width and same reason as sp_submit_assessment above -
    -- this procedure has its own independent ID-generation logic, so the
    -- fix has to be applied here separately, not just in the sibling
    -- procedure.
    SET next_id = CONCAT('SUB', LPAD(next_num, 5, '0'));

    INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)
    VALUES (next_id, p_AssessmentID, p_StudentID, CURDATE(), NULL, TRUE);

    COMMIT;
END //

DELIMITER ;

-- DROP PROCEDURE also drops the routine's privileges, so the grants from
-- 06_generate_submission_ids.sql are gone by this point.
GRANT EXECUTE ON PROCEDURE slms.sp_submit_assessment   TO student_role;
GRANT EXECUTE ON PROCEDURE slms.sp_resubmit_assessment TO student_role;

FLUSH PRIVILEGES;
