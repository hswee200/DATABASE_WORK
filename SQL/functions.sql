-- SLMS functions extracted from the live schema snapshot.
-- Run after create_tables.sql and views.sql.

USE slms;

-- ============================================================================
-- 3. FUNCTIONS
-- ============================================================================

DELIMITER //

-- ---- fn_attendance_rate  (DEFINER: root@localhost) ----
DROP FUNCTION IF EXISTS fn_attendance_rate //
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_attendance_rate`(p_StudentID VARCHAR(20),
    p_CourseID VARCHAR(20)
) RETURNS decimal(5,2)
    DETERMINISTIC
BEGIN
    DECLARE v_total INT;
    DECLARE v_present INT;
    DECLARE v_rate DECIMAL(5,2);

    SELECT COUNT(*)
    INTO v_total
    FROM ATTENDANCE att
    JOIN TIMETABLE t
        ON att.TimetableID = t.TimetableID
    WHERE att.StudentID = p_StudentID
      AND t.CourseID = p_CourseID;

    SELECT COUNT(*)
    INTO v_present
    FROM ATTENDANCE att
    JOIN TIMETABLE t
        ON att.TimetableID = t.TimetableID
    WHERE att.StudentID = p_StudentID
      AND t.CourseID = p_CourseID
      AND att.Status = 'Present';

    IF v_total = 0 THEN
        RETURN 0;
    END IF;

    SET v_rate = ROUND((v_present * 100.0) / v_total, 2);

    RETURN v_rate;
END //

-- ---- fn_calculate_final_grade  (DEFINER: vincentchanayire@localhost) ----
DROP FUNCTION IF EXISTS fn_calculate_final_grade //
CREATE DEFINER=`vincentchanayire`@`localhost` FUNCTION `fn_calculate_final_grade`(p_StudentID VARCHAR(20), p_CourseID VARCHAR(20)) RETURNS decimal(5,2)
    DETERMINISTIC
BEGIN
    DECLARE v_grade DECIMAL(5,2);

    SELECT ROUND(AVG(sub.Score / a.MaxScore * 100), 2)
    INTO v_grade
    FROM SUBMISSION sub
    JOIN ASSESSMENT a
        ON sub.AssessmentID = a.AssessmentID
    WHERE sub.StudentID = p_StudentID
      AND a.CourseID = p_CourseID
      AND sub.IsActive = TRUE;

    RETURN v_grade;
END //

DELIMITER ;

-- ============================================================================
