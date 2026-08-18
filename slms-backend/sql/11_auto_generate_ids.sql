-- Nobody memorizes a raw ID for a person or thing. Five procedures made a
-- caller invent one (UserID/StudentID/LecturerID/AdminID on account
-- creation, AssessmentID on assessment creation, AttendanceID on marking
-- attendance) - this makes all five generate their own ID internally,
-- same MAX(...)+1 / LPAD pattern sp_enroll_student already uses for
-- EnrollmentID. Each ends with a trailing SELECT of the generated ID(s) so
-- the caller can read back what was created, mirroring the CALL -> SELECT
-- convention sp_generate_transcript already uses.
--
-- Widths here are deliberately generous (4-5 digits) from the start - this
-- session already hit and fixed a real bug from under-sizing LPAD width
-- (sql/07_widen_submission_id_width.sql: MariaDB's LPAD truncates a string
-- that's already >= the target width rather than widening it, so a 3-digit
-- width collided once row counts crossed 999). Do not shrink these widths
-- "to match" the shorter IDs already in the seed data - that reintroduces
-- the exact bug this comment is warning about.
--
-- MariaDB has no ALTER PROCEDURE for the body, so this is DROP + CREATE.
-- Must run as root@localhost, which is also the DEFINER for every routine
-- here (matches the DEFINER already on sp_create_student/lecturer/admin and
-- sp_create_assessment; sp_mark_attendance's DEFINER changes from
-- vincentchanayire@localhost to root@localhost as a side effect of this
-- DROP + CREATE, consistent with the rest of this file).

USE slms;

DELIMITER //

DROP PROCEDURE IF EXISTS sp_create_student //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_create_student(
    IN p_Email VARCHAR(100),
    IN p_PasswordHash VARCHAR(255),
    IN p_FName VARCHAR(30),
    IN p_LName VARCHAR(30),
    IN p_DateOfBirth DATE
)
BEGIN
    DECLARE v_RoleID INT;
    DECLARE next_user_num INT;
    DECLARE next_profile_num INT;
    DECLARE v_UserID VARCHAR(20);
    DECLARE v_StudentID VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT RoleID INTO v_RoleID FROM User_Role WHERE RoleName = 'Student';

    SELECT IFNULL(MAX(CAST(SUBSTRING(UserID, 2) AS UNSIGNED)), 0) + 1 INTO next_user_num FROM APP_USER;
    SET v_UserID = CONCAT('U', LPAD(next_user_num, 4, '0'));

    SELECT IFNULL(MAX(CAST(SUBSTRING(StudentID, 2) AS UNSIGNED)), 0) + 1 INTO next_profile_num FROM STUDENT;
    SET v_StudentID = CONCAT('S', LPAD(next_profile_num, 4, '0'));

    START TRANSACTION;

    INSERT INTO APP_USER (UserID, Username, Email, PasswordHash, RoleID)
    VALUES (v_UserID, v_StudentID, p_Email, p_PasswordHash, v_RoleID);

    INSERT INTO STUDENT (StudentID, F_Name, L_Name, UserID, DateOfBirth)
    VALUES (v_StudentID, p_FName, p_LName, v_UserID, p_DateOfBirth);

    COMMIT;

    SELECT v_UserID AS UserID, v_StudentID AS StudentID;
END //

DROP PROCEDURE IF EXISTS sp_create_lecturer //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_create_lecturer(
    IN p_Email VARCHAR(100),
    IN p_PasswordHash VARCHAR(255),
    IN p_FName VARCHAR(30),
    IN p_LName VARCHAR(30),
    IN p_DateOfBirth DATE
)
BEGIN
    DECLARE v_RoleID INT;
    DECLARE next_user_num INT;
    DECLARE next_profile_num INT;
    DECLARE v_UserID VARCHAR(20);
    DECLARE v_LecturerID VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT RoleID INTO v_RoleID FROM User_Role WHERE RoleName = 'Lecturer';

    SELECT IFNULL(MAX(CAST(SUBSTRING(UserID, 2) AS UNSIGNED)), 0) + 1 INTO next_user_num FROM APP_USER;
    SET v_UserID = CONCAT('U', LPAD(next_user_num, 4, '0'));

    SELECT IFNULL(MAX(CAST(SUBSTRING(LecturerID, 2) AS UNSIGNED)), 0) + 1 INTO next_profile_num FROM Lecturer;
    SET v_LecturerID = CONCAT('L', LPAD(next_profile_num, 4, '0'));

    START TRANSACTION;

    INSERT INTO APP_USER (UserID, Username, Email, PasswordHash, RoleID)
    VALUES (v_UserID, v_LecturerID, p_Email, p_PasswordHash, v_RoleID);

    INSERT INTO Lecturer (LecturerID, F_Name, L_Name, UserID, DateOfBirth)
    VALUES (v_LecturerID, p_FName, p_LName, v_UserID, p_DateOfBirth);

    COMMIT;

    SELECT v_UserID AS UserID, v_LecturerID AS LecturerID;
END //

DROP PROCEDURE IF EXISTS sp_create_admin //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_create_admin(
    IN p_Email VARCHAR(100),
    IN p_PasswordHash VARCHAR(255),
    IN p_FName VARCHAR(30),
    IN p_LName VARCHAR(30),
    IN p_DateOfBirth DATE
)
BEGIN
    DECLARE v_RoleID INT;
    DECLARE next_user_num INT;
    DECLARE next_profile_num INT;
    DECLARE v_UserID VARCHAR(20);
    DECLARE v_AdminID VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT RoleID INTO v_RoleID FROM User_Role WHERE RoleName = 'Admin';

    SELECT IFNULL(MAX(CAST(SUBSTRING(UserID, 2) AS UNSIGNED)), 0) + 1 INTO next_user_num FROM APP_USER;
    SET v_UserID = CONCAT('U', LPAD(next_user_num, 4, '0'));

    SELECT IFNULL(MAX(CAST(SUBSTRING(AdminID, 2) AS UNSIGNED)), 0) + 1 INTO next_profile_num FROM Admin_USER;
    SET v_AdminID = CONCAT('A', LPAD(next_profile_num, 4, '0'));

    START TRANSACTION;

    INSERT INTO APP_USER (UserID, Username, Email, PasswordHash, RoleID)
    VALUES (v_UserID, v_AdminID, p_Email, p_PasswordHash, v_RoleID);

    INSERT INTO Admin_USER (AdminID, F_Name, L_Name, UserID, DateOfBirth)
    VALUES (v_AdminID, p_FName, p_LName, v_UserID, p_DateOfBirth);

    COMMIT;

    SELECT v_UserID AS UserID, v_AdminID AS AdminID;
END //

DROP PROCEDURE IF EXISTS sp_create_assessment //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_create_assessment(
    IN p_CourseID VARCHAR(20),
    IN p_AssessmentType VARCHAR(50),
    IN p_AssessmentName VARCHAR(100),
    IN p_MaxScore DECIMAL(5,2),
    IN p_DueDate DATE,
    IN p_AssessmentCategory VARCHAR(10)
)
BEGIN
    DECLARE next_num INT;
    DECLARE v_AssessmentID VARCHAR(20);

    IF p_AssessmentCategory = 'Midsem' AND EXISTS (
        SELECT 1 FROM ASSESSMENT WHERE CourseID = p_CourseID AND AssessmentCategory = 'Midsem'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This course already has a Midsem assessment.';
    ELSEIF p_AssessmentCategory = 'Final' AND EXISTS (
        SELECT 1 FROM ASSESSMENT WHERE CourseID = p_CourseID AND AssessmentCategory = 'Final'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This course already has a Final assessment.';
    ELSE
        SELECT IFNULL(MAX(CAST(SUBSTRING(AssessmentID, 3) AS UNSIGNED)), 0) + 1 INTO next_num FROM ASSESSMENT;
        SET v_AssessmentID = CONCAT('AS', LPAD(next_num, 4, '0'));

        INSERT INTO ASSESSMENT (AssessmentID, CourseID, AssessmentType, AssessmentName, MaxScore, DueDate, AssessmentCategory)
        VALUES (v_AssessmentID, p_CourseID, p_AssessmentType, p_AssessmentName, p_MaxScore, p_DueDate, p_AssessmentCategory);

        SELECT v_AssessmentID AS AssessmentID;
    END IF;
END //

DROP PROCEDURE IF EXISTS sp_mark_attendance //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_mark_attendance(
    IN p_StudentID VARCHAR(20),
    IN p_TimetableID VARCHAR(20),
    IN p_AttendanceDate DATE,
    IN p_Status VARCHAR(10)
)
BEGIN
    DECLARE next_num INT;
    DECLARE v_AttendanceID VARCHAR(20);

    IF p_Status NOT IN ('Present', 'Absent', 'Late') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status value.';
    ELSE
        SELECT IFNULL(MAX(CAST(SUBSTRING(AttendanceID, 4) AS UNSIGNED)), 0) + 1 INTO next_num FROM ATTENDANCE;
        SET v_AttendanceID = CONCAT('ATT', LPAD(next_num, 5, '0'));

        INSERT INTO ATTENDANCE (AttendanceID, StudentID, TimetableID, AttendanceDate, Status)
        VALUES (v_AttendanceID, p_StudentID, p_TimetableID, p_AttendanceDate, p_Status);

        SELECT v_AttendanceID AS AttendanceID;
    END IF;
END //

DELIMITER ;

-- DROP PROCEDURE also drops the routine's privileges. sp_create_student/
-- lecturer/admin never needed an explicit grant (admin_role's blanket
-- "GRANT ALL PRIVILEGES ON slms.*" already covers EXECUTE on every routine
-- in the schema) - only lecturer_role's two need reissuing here.
GRANT EXECUTE ON PROCEDURE slms.sp_create_assessment TO lecturer_role;
GRANT EXECUTE ON PROCEDURE slms.sp_mark_attendance TO lecturer_role;

FLUSH PRIVILEGES;
