-- SLMS triggers extracted from the live schema snapshot.
-- Run after create_tables.sql and procedures_functions.sql.

USE slms;

-- ============================================================================

DELIMITER //

-- ---- trg_log_score_change ----
DROP TRIGGER IF EXISTS trg_log_score_change //
CREATE DEFINER=`root`@`localhost` TRIGGER trg_log_score_change
AFTER UPDATE ON SUBMISSION
FOR EACH ROW
BEGIN
    IF OLD.Score <> NEW.Score
       OR (OLD.Score IS NULL AND NEW.Score IS NOT NULL) THEN

        INSERT INTO SUBMISSION_AUDIT_LOG
            (SubmissionID, OldScore, NewScore)
        VALUES
            (NEW.SubmissionID, OLD.Score, NEW.Score);

    END IF;
END //

-- ---- trg_prevent_duplicate_attendance ----
DROP TRIGGER IF EXISTS trg_prevent_duplicate_attendance //
CREATE DEFINER=`root`@`localhost` TRIGGER trg_prevent_duplicate_attendance
BEFORE INSERT ON ATTENDANCE
FOR EACH ROW
BEGIN
    DECLARE existing_count INT;

    SELECT COUNT(*) INTO existing_count
    FROM ATTENDANCE
    WHERE StudentID = NEW.StudentID
      AND TimetableID = NEW.TimetableID
      AND AttendanceDate = NEW.AttendanceDate;

    IF existing_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Duplicate attendance record for this student, session, and date.';
    END IF;
END //

-- ---- trg_validate_submission_score ----
DROP TRIGGER IF EXISTS trg_validate_submission_score //
CREATE DEFINER=`root`@`localhost` TRIGGER trg_validate_submission_score
BEFORE INSERT ON SUBMISSION
FOR EACH ROW
BEGIN
    DECLARE allowed_max DECIMAL(5,2);

    SELECT MaxScore
    INTO allowed_max
    FROM ASSESSMENT
    WHERE AssessmentID = NEW.AssessmentID;

    IF NEW.Score IS NOT NULL
       AND NEW.Score > allowed_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Score exceeds the maximum allowed for this assessment.';
    END IF;
END //

DELIMITER ;

