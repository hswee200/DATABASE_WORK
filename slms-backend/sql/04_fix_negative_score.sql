-- sp_record_grade rejected scores above MaxScore but had no lower bound, so a
-- negative score was stored without complaint. This moves that guard into the
-- database so it holds regardless of which client calls the procedure. The
-- app-level check in the backend stays as a second layer.
--
-- MariaDB has no ALTER PROCEDURE for the body, so this is DROP + CREATE.
-- Must run as root@localhost, which is also the procedure's DEFINER.

USE SLMS;

DELIMITER //

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
    WHERE SubmissionID = p_SubmissionID;

    SELECT MaxScore
    INTO v_MaxScore
    FROM ASSESSMENT
    WHERE AssessmentID = v_AssessmentID;

    -- Split into two branches rather than one combined condition so the caller
    -- is told which rule it broke. The backend returns MESSAGE_TEXT straight to
    -- the client, so a negative score reporting "exceeds the maximum" would be
    -- actively misleading.
    IF p_Score > v_MaxScore THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Score exceeds the maximum allowed for this assessment.';
    ELSEIF p_Score < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Score cannot be negative.';
    ELSE
        UPDATE SUBMISSION
        SET Score = p_Score
        WHERE SubmissionID = p_SubmissionID;
    END IF;
END //

DELIMITER ;

-- DROP PROCEDURE also drops the routine's privileges, so the EXECUTE grant
-- added in 03_grant_execute.sql is gone by this point. Without this line,
-- lecturers would start getting 500s when grading.
GRANT EXECUTE ON PROCEDURE SLMS.sp_record_grade TO lecturer_role;

FLUSH PRIVILEGES;
