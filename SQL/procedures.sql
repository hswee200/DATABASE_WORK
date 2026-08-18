-- SLMS stored procedures extracted from the live schema snapshot.
-- Run after create_tables.sql and views.sql.

USE slms;

-- ============================================================================

DELIMITER //

-- ---- sp_change_password  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_change_password //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_change_password`(
    IN p_UserID VARCHAR(20),
    IN p_NewPasswordHash VARCHAR(255)
)
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM APP_USER WHERE UserID = p_UserID AND IsActive = TRUE;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found or inactive.';
    ELSE
        UPDATE APP_USER SET PasswordHash = p_NewPasswordHash WHERE UserID = p_UserID;
    END IF;
END //

-- ---- sp_create_admin  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_create_admin //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_admin`(
    IN p_UserID VARCHAR(20),
    IN p_AdminID VARCHAR(20),
    IN p_Email VARCHAR(100),
    IN p_PasswordHash VARCHAR(255),
    IN p_FName VARCHAR(30),
    IN p_LName VARCHAR(30),
    IN p_DateOfBirth DATE
)
BEGIN
    DECLARE v_RoleID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT RoleID
    INTO v_RoleID
    FROM User_Role
    WHERE RoleName = 'Admin';

    START TRANSACTION;

    INSERT INTO APP_USER
        (UserID, Username, Email, PasswordHash, RoleID)
    VALUES
        (p_UserID, p_AdminID, p_Email, p_PasswordHash, v_RoleID);

    INSERT INTO Admin_USER
        (AdminID, F_Name, L_Name, UserID, DateOfBirth)
    VALUES
        (p_AdminID, p_FName, p_LName, p_UserID, p_DateOfBirth);

    COMMIT;
END //

-- ---- sp_create_assessment  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_create_assessment //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_assessment`(
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

-- ---- sp_create_lecturer  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_create_lecturer //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_lecturer`(
    IN p_UserID VARCHAR(20),
    IN p_LecturerID VARCHAR(20),
    IN p_Email VARCHAR(100),
    IN p_PasswordHash VARCHAR(255),
    IN p_FName VARCHAR(30),
    IN p_LName VARCHAR(30),
    IN p_DateOfBirth DATE
)
BEGIN
    DECLARE v_RoleID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT RoleID
    INTO v_RoleID
    FROM User_Role
    WHERE RoleName = 'Lecturer';

    START TRANSACTION;

    INSERT INTO APP_USER
        (UserID, Username, Email, PasswordHash, RoleID)
    VALUES
        (p_UserID, p_LecturerID, p_Email, p_PasswordHash, v_RoleID);

    INSERT INTO Lecturer
        (LecturerID, F_Name, L_Name, UserID, DateOfBirth)
    VALUES
        (p_LecturerID, p_FName, p_LName, p_UserID, p_DateOfBirth);

    COMMIT;
END //

-- ---- sp_create_student  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_create_student //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_student`(
    IN p_UserID VARCHAR(20),
    IN p_StudentID VARCHAR(20),
    IN p_Email VARCHAR(100),
    IN p_PasswordHash VARCHAR(255),
    IN p_FName VARCHAR(30),
    IN p_LName VARCHAR(30),
    IN p_DateOfBirth DATE
)
BEGIN
    DECLARE v_RoleID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT RoleID
    INTO v_RoleID
    FROM User_Role
    WHERE RoleName = 'Student';

    START TRANSACTION;

    INSERT INTO APP_USER
        (UserID, Username, Email, PasswordHash, RoleID)
    VALUES
        (p_UserID, p_StudentID, p_Email, p_PasswordHash, v_RoleID);

    INSERT INTO STUDENT
        (StudentID, F_Name, L_Name, UserID, DateOfBirth)
    VALUES
        (p_StudentID, p_FName, p_LName, p_UserID, p_DateOfBirth);

    COMMIT;
END //

-- ---- sp_deactivate_user  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_deactivate_user //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_deactivate_user`(IN p_UserID VARCHAR(20))
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM APP_USER WHERE UserID = p_UserID AND IsActive = TRUE;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found or already inactive.';
    ELSE
        UPDATE APP_USER SET IsActive = FALSE WHERE UserID = p_UserID;
    END IF;
END //

-- ---- sp_delete_attendance  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_delete_attendance //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_delete_attendance`(IN p_AttendanceID VARCHAR(20))
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM ATTENDANCE WHERE AttendanceID = p_AttendanceID;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Attendance record not found.';
    ELSE
        DELETE FROM ATTENDANCE WHERE AttendanceID = p_AttendanceID;
    END IF;
END //

-- ---- sp_delete_submission  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_delete_submission //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_delete_submission`(IN p_SubmissionID VARCHAR(20))
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM SUBMISSION WHERE SubmissionID = p_SubmissionID AND IsActive = TRUE;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Submission not found or already inactive.';
    ELSE
        UPDATE SUBMISSION SET IsActive = FALSE WHERE SubmissionID = p_SubmissionID;
    END IF;
END //

-- ---- sp_enroll_student  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_enroll_student //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_enroll_student`(
    IN p_StudentID VARCHAR(20),
    IN p_CourseID VARCHAR(20)
)
BEGIN
    DECLARE already_enrolled INT;
    DECLARE next_num INT;

    SELECT COUNT(*) INTO already_enrolled
    FROM ENROLLMENT
    WHERE StudentID = p_StudentID
      AND CourseID = p_CourseID;

    IF already_enrolled > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This student is already enrolled in this course.';
    ELSE
        SELECT IFNULL(MAX(CAST(SUBSTRING(EnrollmentID, 2) AS UNSIGNED)), 0) + 1
        INTO next_num
        FROM ENROLLMENT;

        INSERT INTO ENROLLMENT (EnrollmentID, StudentID, CourseID, EnrollmentDate)
        VALUES (
            CONCAT('E', LPAD(next_num, 3, '0')),
            p_StudentID,
            p_CourseID,
            CURDATE()
        );
    END IF;
END //

-- ---- sp_generate_transcript  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_generate_transcript //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_generate_transcript`(IN p_StudentID VARCHAR(20))
BEGIN
    SELECT F_Name, L_Name, SemesterName, AcademicYear, CourseID, CourseName, FinalGradePercent, LetterGrade
    FROM VW_STUDENT_FINAL_GRADES
    WHERE StudentID = p_StudentID
    ORDER BY AcademicYear, SemesterName;
END //

-- ---- sp_mark_attendance  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_mark_attendance //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_mark_attendance`(
    IN p_AttendanceID VARCHAR(20),
    IN p_StudentID VARCHAR(20),
    IN p_TimetableID VARCHAR(20),
    IN p_AttendanceDate DATE,
    IN p_Status VARCHAR(10)
)
BEGIN
    IF p_Status NOT IN ('Present', 'Absent', 'Late') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status value.';
    ELSE
        
        
        INSERT INTO ATTENDANCE (AttendanceID, StudentID, TimetableID, AttendanceDate, Status)
        VALUES (p_AttendanceID, p_StudentID, p_TimetableID, p_AttendanceDate, p_Status);
    END IF;
END //

-- ---- sp_reassign_course_lecturer  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_reassign_course_lecturer //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_reassign_course_lecturer`(
    IN p_CourseID VARCHAR(20),
    IN p_NewLecturerID VARCHAR(20)
)
BEGIN
    DECLARE lecturer_exists INT;
    SELECT COUNT(*) INTO lecturer_exists FROM Lecturer WHERE LecturerID = p_NewLecturerID;
    IF lecturer_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lecturer not found.';
    ELSE
        UPDATE COURSE SET LecturerID = p_NewLecturerID WHERE CourseID = p_CourseID;
    END IF;
END //

-- ---- sp_record_grade  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_record_grade //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_record_grade`(
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

-- ---- sp_resubmit_assessment  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_resubmit_assessment //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_resubmit_assessment`(
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

    
    
    
    
    SET next_id = CONCAT('SUB', LPAD(next_num, 5, '0'));

    INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)
    VALUES (next_id, p_AssessmentID, p_StudentID, CURDATE(), NULL, TRUE);

    COMMIT;
END //

-- ---- sp_submit_assessment  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_submit_assessment //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_submit_assessment`(
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

        
        
        
        SET next_id = CONCAT('SUB', LPAD(next_num, 5, '0'));

        INSERT INTO SUBMISSION (SubmissionID, AssessmentID, StudentID, SubmissionDate, Score, IsActive)
        VALUES (next_id, p_AssessmentID, p_StudentID, CURDATE(), NULL, TRUE);
    END IF;
END //

-- ---- sp_unenroll_student  (DEFINER: root@localhost) ----
DROP PROCEDURE IF EXISTS sp_unenroll_student //
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_unenroll_student`(
    IN p_StudentID VARCHAR(20),
    IN p_CourseID VARCHAR(20)
)
BEGIN
    DECLARE existing_count INT;

    SELECT COUNT(*) INTO existing_count
    FROM ENROLLMENT
    WHERE StudentID = p_StudentID
      AND CourseID = p_CourseID;

    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No enrollment found for this student in this course.';
    ELSE
        DELETE FROM ENROLLMENT
        WHERE StudentID = p_StudentID
          AND CourseID = p_CourseID;
    END IF;
END //

-- ---- sp_update_assessment  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_update_assessment //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_update_assessment`(
    IN p_AssessmentID VARCHAR(20),
    IN p_DueDate DATE,
    IN p_MaxScore DECIMAL(5,2)
)
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM ASSESSMENT WHERE AssessmentID = p_AssessmentID;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assessment not found.';
    ELSE
        UPDATE ASSESSMENT
        SET DueDate = p_DueDate, MaxScore = p_MaxScore
        WHERE AssessmentID = p_AssessmentID;
    END IF;
END //

-- ---- sp_update_attendance_status  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_update_attendance_status //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_update_attendance_status`(
    IN p_AttendanceID VARCHAR(20),
    IN p_Status VARCHAR(10)
)
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM ATTENDANCE WHERE AttendanceID = p_AttendanceID;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Attendance record not found.';
    ELSEIF p_Status NOT IN ('Present', 'Absent', 'Late') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status value.';
    ELSE
        UPDATE ATTENDANCE SET Status = p_Status WHERE AttendanceID = p_AttendanceID;
    END IF;
END //

-- ---- sp_update_timetable  (DEFINER: vincentchanayire@localhost) ----
DROP PROCEDURE IF EXISTS sp_update_timetable //
CREATE DEFINER=`vincentchanayire`@`localhost` PROCEDURE `sp_update_timetable`(
    IN p_TimetableID VARCHAR(20),
    IN p_DayOfWeek VARCHAR(10),
    IN p_StartTime TIME,
    IN p_EndTime TIME,
    IN p_Room VARCHAR(20)
)
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM TIMETABLE WHERE TimetableID = p_TimetableID;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Timetable entry not found.';
    ELSE
        UPDATE TIMETABLE
        SET DayOfWeek = p_DayOfWeek, StartTime = p_StartTime, EndTime = p_EndTime, Room = p_Room
        WHERE TimetableID = p_TimetableID;
    END IF;
END //

DELIMITER ;

-- ============================================================================
