

CREATE DATABASE  slms;
USE slms;

select * from student;
show tables;
show databases;
DESCRIBE APP_USER;
DESCRIBE STUDENT;
DESCRIBE COURSE;
DESCRIBE ENROLLMENT;
DESCRIBE ATTENDANCE;
DESCRIBE ASSESSMENT;
DESCRIBE SUBMISSION;



SELECT * FROM STUDENT;
SELECT * FROM COURSE;
SELECT * FROM ENROLLMENT;
SELECT * FROM ASSESSMENT;
SELECT * FROM SUBMISSION;
SELECT * FROM ATTENDANCE;




-- ============================================================================
-- 1. TABLES
-- ============================================================================

-- ---- User_Role ----
CREATE TABLE User_Role (
  RoleID INT NOT NULL AUTO_INCREMENT,
  RoleName varchar(20) NOT NULL,
  PRIMARY KEY (RoleID),
  UNIQUE KEY RoleName (RoleName)
);


-- ---- Admin_USER ----
CREATE TABLE Admin_USER (
  AdminID varchar(20) NOT NULL,
  F_Name varchar(30) NOT NULL,
  L_Name varchar(30) NOT NULL,
  UserID varchar(20) NOT NULL,
  DateOfBirth date DEFAULT NULL,
  PRIMARY KEY (AdminID),
  UNIQUE KEY UserID (UserID),
  CONSTRAINT fk_admin_user_user FOREIGN KEY (UserID) REFERENCES APP_USER (UserID)
);

-- ---- APP_USER ----
CREATE TABLE APP_USER (
  UserID varchar(20) NOT NULL,
  Username varchar(20) NOT NULL,
  Email varchar(100) NOT NULL,
  PasswordHash varchar(255) NOT NULL,
  RoleID INT NOT NULL,
  IsActive TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (UserID),
  UNIQUE KEY Username (Username),
  UNIQUE KEY Email (Email),
  KEY RoleID (RoleID),
  CONSTRAINT fk_app_user_role FOREIGN KEY (RoleID) REFERENCES User_Role (RoleID)
);


-- ---- ASSESSMENT ----
CREATE TABLE ASSESSMENT (
  AssessmentID varchar(20) NOT NULL,
  CourseID varchar(20) NOT NULL,
  AssessmentType varchar(50) NOT NULL,
  AssessmentName varchar(100) NOT NULL,
  MaxScore decimal(5,2) NOT NULL,
  DueDate date DEFAULT NULL,
  AssessmentCategory enum('Regular','Midsem','Final') NOT NULL DEFAULT 'Regular',
  PRIMARY KEY (AssessmentID),
  KEY CourseID (CourseID),
  CONSTRAINT fk_assessment_course FOREIGN KEY (CourseID) REFERENCES COURSE (CourseID)
);

-- ---- ATTENDANCE ----
CREATE TABLE ATTENDANCE (
  AttendanceID varchar(20) NOT NULL,
  StudentID varchar(20) NOT NULL,
  TimetableID varchar(20) NOT NULL,
  AttendanceDate date NOT NULL,
  Status varchar(10) NOT NULL CHECK (Status in ('Present','Absent','Late')),
  PRIMARY KEY (AttendanceID),
  KEY StudentID (StudentID),
  KEY TimetableID (TimetableID),
  CONSTRAINT fk_attendance_student FOREIGN KEY (StudentID) REFERENCES STUDENT (StudentID),
  CONSTRAINT fk_attendance_timetable FOREIGN KEY (TimetableID) REFERENCES TIMETABLE (TimetableID)
);

-- ---- COURSE ----
CREATE TABLE COURSE (
  CourseID varchar(20) NOT NULL,
  CourseName varchar(100) NOT NULL,
  CourseCode varchar(20) NOT NULL,
  CreditHours INT NOT NULL,
  LecturerID varchar(20) NOT NULL,
  SemesterID varchar(20) NOT NULL,
  DepartmentID varchar(20) NOT NULL,
  PRIMARY KEY (CourseID),
  UNIQUE KEY CourseCode (CourseCode),
  KEY LecturerID (LecturerID),
  KEY SemesterID (SemesterID),
  KEY DepartmentID(DepartmentID),
  CONSTRAINT fk_course_lecturer FOREIGN KEY (LecturerID) REFERENCES Lecturer (LecturerID),
  CONSTRAINT fk_course_semester FOREIGN KEY (SemesterID) REFERENCES Semester (SemesterID),
  CONSTRAINT fk_course_department FOREIGN KEY (DepartmentID) REFERENCES Department (DepartmentID)
);

-- ---- ENROLLMENT ----
CREATE TABLE ENROLLMENT (
  EnrollmentID varchar(20) NOT NULL,
  StudentID varchar(20) NOT NULL,
  CourseID varchar(20) NOT NULL,
  EnrollmentDate date NOT NULL,
  PRIMARY KEY (EnrollmentID),
  KEY StudentID (StudentID),
  KEY CourseID (CourseID),
  CONSTRAINT fk_enrollment_student FOREIGN KEY (StudentID) REFERENCES STUDENT (StudentID),
  CONSTRAINT fk_enrollment_course FOREIGN KEY (CourseID) REFERENCES COURSE (CourseID)
);

-- ---- Lecturer ----
CREATE TABLE Lecturer (
  LecturerID varchar(20) NOT NULL,
  F_Name varchar(30) NOT NULL,
  L_Name varchar(30) NOT NULL,
  UserID varchar(20) NOT NULL,
  DateOfBirth date DEFAULT NULL,
  PRIMARY KEY (LecturerID),
  UNIQUE KEY UserID (UserID),
  CONSTRAINT fk_lecturer_user FOREIGN KEY (UserID) REFERENCES APP_USER (UserID)
);

-- ---- SEMESTER ----
CREATE TABLE SEMESTER (
  SemesterID varchar(20) NOT NULL,
  SemesterName varchar(60) NOT NULL,
  AcademicYear varchar(20) NOT NULL,
  StartDate date DEFAULT NULL,
  EndDate date DEFAULT NULL,
  PRIMARY KEY (SemesterID)
);

-- ---- STUDENT ----
CREATE TABLE STUDENT (
  StudentID varchar(20) NOT NULL,
  F_Name varchar(30) NOT NULL,
  L_Name varchar(30) NOT NULL,
  UserID varchar(20) NOT NULL,
  DateOfBirth date DEFAULT NULL,
  PRIMARY KEY (StudentID),
  UNIQUE KEY UserID (UserID),
  CONSTRAINT fk_student_user FOREIGN KEY (UserID) REFERENCES APP_USER (UserID)
);

-- ---- SUBMISSION ----
CREATE TABLE SUBMISSION (
  SubmissionID varchar(20) NOT NULL,
  AssessmentID varchar(20) NOT NULL,
  StudentID varchar(20) NOT NULL,
  SubmissionDate date DEFAULT NULL,
  Score decimal(5,2) DEFAULT NULL,
  IsActive TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (SubmissionID),
  KEY AssessmentID (AssessmentID),
  KEY StudentID (StudentID),
  
  CONSTRAINT fk_submission_assessment FOREIGN KEY (AssessmentID) REFERENCES ASSESSMENT (AssessmentID),
  CONSTRAINT fk_submission_student FOREIGN KEY (StudentID) REFERENCES STUDENT (StudentID)
);

-- ---- SUBMISSION_AUDIT_LOG ----
CREATE TABLE SUBMISSION_AUDIT_LOG (
  LogID INT NOT NULL AUTO_INCREMENT,
  SubmissionID varchar(20) NOT NULL,
  OldScore decimal(5,2) DEFAULT NULL,
  NewScore decimal(5,2) DEFAULT NULL,
  ChangedAt timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (LogID),
  KEY SubmissionID (SubmissionID),
  CONSTRAINT fk_audit_submission FOREIGN KEY (SubmissionID) REFERENCES SUBMISSION (SubmissionID)
);

-- ---- TIMETABLE ----
CREATE TABLE TIMETABLE (
  TimetableID varchar(20) NOT NULL,
  CourseID varchar(20) NOT NULL,
  DayOfWeek varchar(10) NOT NULL,
  StartTime time NOT NULL,
  EndTime time NOT NULL,
  Room varchar(20) DEFAULT NULL,
  PRIMARY KEY (TimetableID),
  KEY CourseID (CourseID),
  CONSTRAINT fk_timetable_course FOREIGN KEY (CourseID) REFERENCES COURSE (CourseID)
);



-- ============================================================================
-- 2. VIEWS
-- ============================================================================

-- ---- vw_assessment_status ----
CREATE VIEW vw_assessment_status AS
SELECT
    e.StudentID AS StudentID,
    a.AssessmentID AS AssessmentID,
    a.AssessmentName AS AssessmentName,
    a.CourseID AS CourseID,
    a.DueDate AS DueDate,
    sub.SubmissionID AS SubmissionID,
    case when sub.SubmissionID is not null then 'Submitted' when a.DueDate < curdate() then 'Past-Due' else 'Upcoming' end AS Status
FROM ((enrollment e
JOIN assessment a ON(e.CourseID = a.CourseID))
LEFT JOIN submission sub ON(sub.AssessmentID = a.AssessmentID and sub.StudentID = e.StudentID and sub.IsActive = 1));

-- ---- vw_attendance_summary ----
CREATE VIEW vw_attendance_summary AS
SELECT
    st.StudentID AS StudentID,
    st.F_Name AS F_Name,
    st.L_Name AS L_Name,
    c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    sum(case when att.Status = 'Present' then 1 else 0 end) AS TimesPresent,
    sum(case when att.Status = 'Absent' then 1 else 0 end) AS TimesAbsent,
    sum(case when att.Status = 'Late' then 1 else 0 end) AS TimesLate,
    COUNT(*) AS TotalSessions,
    round(sum(case when att.Status = 'Present' then 1 else 0 end) * 100.0 / COUNT(*),2) AS AttendanceRate
FROM (((attendance att
JOIN timetable t ON(att.TimetableID = t.TimetableID))
JOIN course c ON(t.CourseID = c.CourseID))
JOIN student st ON(att.StudentID = st.StudentID))
GROUP BY st.StudentID,st.F_Name,st.L_Name,c.CourseID,c.CourseName;

-- ---- vw_below_class_average ----
CREATE VIEW vw_below_class_average AS
SELECT
    y.CourseID AS CourseID,
    y.CourseName AS CourseName,
    y.StudentID AS StudentID,
    y.F_Name AS F_Name,
    y.L_Name AS L_Name,
    y.StudentAvg AS StudentAvg,
    avg(y.StudentAvg) over ( partition by y.CourseID) AS ClassAvg
FROM (SELECT c.CourseID AS CourseID,c.CourseName AS CourseName,st.StudentID AS StudentID,st.F_Name AS F_Name,st.L_Name AS L_Name,avg(sub.Score) AS StudentAvg FROM (((submission sub
JOIN assessment a ON(sub.AssessmentID = a.AssessmentID))
JOIN course c ON(a.CourseID = c.CourseID))
JOIN student st ON(sub.StudentID = st.StudentID))
WHERE sub.IsActive = 1
GROUP BY c.CourseID,c.CourseName,st.StudentID,st.F_Name,st.L_Name) y;

-- ---- vw_courses_without_assessments ----
CREATE VIEW vw_courses_without_assessments AS
SELECT
    distinct c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    c.CourseCode AS CourseCode
FROM (course c
LEFT JOIN assessment a ON(c.CourseID = a.CourseID))
WHERE a.AssessmentID is null;

-- ---- vw_course_enrollment_ranking ----
CREATE VIEW vw_course_enrollment_ranking AS
SELECT
    c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    count(e.StudentID) AS EnrolledStudents,
    rank() over ( ORDER BY count(e.StudentID) desc) AS EnrollmentRank
FROM (course c
JOIN enrollment e ON(c.CourseID = e.CourseID))
GROUP BY c.CourseID,c.CourseName;

-- ---- vw_course_grades ----
CREATE VIEW vw_course_grades AS
SELECT
    e.StudentID AS StudentID,
    st.F_Name AS F_Name,
    st.L_Name AS L_Name,
    a.CourseID AS CourseID,
    a.AssessmentID AS AssessmentID,
    a.AssessmentName AS AssessmentName,
    a.AssessmentCategory AS AssessmentCategory,
    a.MaxScore AS MaxScore,
    sub.Score AS Score,
    sub.SubmissionID AS SubmissionID,
    case a.AssessmentCategory when 'Midsem' then 20 when 'Final' then 40 else (100 - if(exists(SELECT 1 FROM assessment a2 WHERE a2.CourseID = a.CourseID and a2.AssessmentCategory = 'Midsem' LIMIT 1),20,0) - if(exists(SELECT 1 FROM assessment a2 WHERE a2.CourseID = a.CourseID and a2.AssessmentCategory = 'Final' LIMIT 1),40,0)) / nullif((SELECT COUNT(*) FROM assessment a3 WHERE a3.CourseID = a.CourseID and a3.AssessmentCategory = 'Regular'),0) end AS Weight
FROM (((assessment a
JOIN enrollment e ON(e.CourseID = a.CourseID))
JOIN student st ON(st.StudentID = e.StudentID))
LEFT JOIN submission sub ON(sub.AssessmentID = a.AssessmentID and sub.StudentID = e.StudentID and sub.IsActive = 1));

-- ---- vw_course_performance_ranking ----
CREATE VIEW vw_course_performance_ranking AS
SELECT
    c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    round(avg(sub.Score * 100.0 / a.MaxScore),1) AS AvgScorePct,
    rank() over ( ORDER BY avg(sub.Score * 100.0 / a.MaxScore)) AS LowPerformanceRank
FROM ((submission sub
JOIN assessment a ON(sub.AssessmentID = a.AssessmentID))
JOIN course c ON(a.CourseID = c.CourseID))
WHERE sub.IsActive = 1
GROUP BY c.CourseID,c.CourseName;

-- ---- vw_course_roster ----
CREATE VIEW vw_course_roster AS
SELECT
    c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    l.F_Name AS LecturerFirstName,
    l.L_Name AS LecturerLastName,
    st.StudentID AS StudentID,
    st.F_Name AS StudentFirstName,
    st.L_Name AS StudentLastName,
    e.EnrollmentDate AS EnrollmentDate
FROM (((enrollment e
JOIN course c ON(e.CourseID = c.CourseID))
JOIN lecturer l ON(c.LecturerID = l.LecturerID))
JOIN student st ON(e.StudentID = st.StudentID));

-- ---- vw_course_score_ranking ----
CREATE VIEW vw_course_score_ranking AS
SELECT
    c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    st.StudentID AS StudentID,
    st.F_Name AS F_Name,
    st.L_Name AS L_Name,
    round(avg(sub.Score),2) AS AvgScore,
    rank() over ( partition by c.CourseID ORDER BY avg(sub.Score) desc) AS RankInCourse
FROM ((((submission sub
JOIN assessment a ON(sub.AssessmentID = a.AssessmentID))
JOIN course c ON(a.CourseID = c.CourseID))
JOIN student st ON(sub.StudentID = st.StudentID))
JOIN enrollment e ON(e.StudentID = st.StudentID and e.CourseID = c.CourseID))
WHERE sub.IsActive = 1
GROUP BY c.CourseID,c.CourseName,st.StudentID,st.F_Name,st.L_Name;

-- ---- vw_late_submissions ----
CREATE VIEW vw_late_submissions AS
SELECT
    st.StudentID AS StudentID,
    st.F_Name AS F_Name,
    st.L_Name AS L_Name,
    c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    a.AssessmentName AS AssessmentName,
    a.DueDate AS DueDate,
    sub.SubmissionDate AS SubmissionDate,
    to_days(sub.SubmissionDate) - to_days(a.DueDate) AS DaysLate,
    rank() over ( partition by c.CourseID ORDER BY to_days(sub.SubmissionDate) - to_days(a.DueDate) desc) AS LatenessRankInCourse
FROM (((submission sub
JOIN assessment a ON(sub.AssessmentID = a.AssessmentID))
JOIN course c ON(a.CourseID = c.CourseID))
JOIN student st ON(sub.StudentID = st.StudentID))
WHERE sub.IsActive = 1 and sub.SubmissionDate > a.DueDate;

-- ---- vw_lecturer_load ----
CREATE VIEW vw_lecturer_load AS
SELECT
    l.LecturerID AS LecturerID,
    l.F_Name AS F_Name,
    l.L_Name AS L_Name,
    count(distinct c.CourseID) AS NumCourses,
    count(distinct e.StudentID) AS NumStudents
FROM ((lecturer l
LEFT JOIN course c ON(l.LecturerID = c.LecturerID))
LEFT JOIN enrollment e ON(c.CourseID = e.CourseID))
GROUP BY l.LecturerID;

-- ---- vw_lecturer_timetable ----
CREATE VIEW vw_lecturer_timetable AS
SELECT
    l.LecturerID AS LecturerID,
    l.F_Name AS F_Name,
    l.L_Name AS L_Name,
    c.CourseID AS CourseID,
    c.CourseCode AS CourseCode,
    c.CourseName AS CourseName,
    s.SemesterName AS SemesterName,
    s.AcademicYear AS AcademicYear,
    t.DayOfWeek AS DayOfWeek,
    t.StartTime AS StartTime,
    t.EndTime AS EndTime,
    t.Room AS Room
FROM (((lecturer l
JOIN course c ON(l.LecturerID = c.LecturerID))
JOIN timetable t ON(c.CourseID = t.CourseID))
JOIN semester s ON(c.SemesterID = s.SemesterID));

-- ---- vw_never_absent_students ----
CREATE VIEW vw_never_absent_students AS
SELECT
    st.StudentID AS StudentID,
    st.F_Name AS F_Name,
    st.L_Name AS L_Name
FROM student st
WHERE exists(SELECT 1 FROM attendance att
WHERE att.StudentID = st.StudentID LIMIT 1) and !exists(SELECT 1 FROM attendance att
WHERE att.StudentID = st.StudentID and att.Status = 'Absent' LIMIT 1);

-- ---- vw_student_final_grades ----
CREATE VIEW vw_student_final_grades AS
SELECT
    x.StudentID AS StudentID,
    x.F_Name AS F_Name,
    x.L_Name AS L_Name,
    x.SemesterID AS SemesterID,
    x.SemesterName AS SemesterName,
    x.AcademicYear AS AcademicYear,
    x.CourseID AS CourseID,
    x.CourseName AS CourseName,
    x.CreditHours AS CreditHours,
    x.FinalGradePercent AS FinalGradePercent,
    case when x.FinalGradePercent >= 90 then 'A+' when x.FinalGradePercent >= 80 then 'A' when x.FinalGradePercent >= 70 then 'B' when x.FinalGradePercent >= 60 then 'C' when x.FinalGradePercent >= 50 then 'D' else 'F' end AS LetterGrade,
    case when x.FinalGradePercent >= 80 then 4.0 when x.FinalGradePercent >= 70 then 3.0 when x.FinalGradePercent >= 60 then 2.0 when x.FinalGradePercent >= 50 then 1.0 else 0.0 end AS GradePoint
FROM (SELECT g.StudentID AS StudentID,g.F_Name AS F_Name,g.L_Name AS L_Name,c.SemesterID AS SemesterID,s.SemesterName AS SemesterName,s.AcademicYear AS AcademicYear,c.CourseID AS CourseID,c.CourseName AS CourseName,c.CreditHours AS CreditHours,round(sum(g.Score / g.MaxScore * g.Weight) / sum(g.Weight) * 100,2) AS FinalGradePercent FROM ((vw_course_grades g
JOIN course c ON(c.CourseID = g.CourseID))
JOIN semester s ON(c.SemesterID = s.SemesterID))
WHERE g.Score is not null
GROUP BY g.StudentID,g.F_Name,g.L_Name,c.SemesterID,s.SemesterName,s.AcademicYear,c.CourseID,c.CourseName,c.CreditHours) x;

-- ---- vw_student_gpa ----
CREATE VIEW vw_student_gpa AS
SELECT
    y.StudentID AS StudentID,
    y.SemesterID AS SemesterID,
    y.SemesterName AS SemesterName,
    y.AcademicYear AS AcademicYear,
    y.SemesterGPA AS SemesterGPA,
    round(sum(y.QualityPoints) over ( partition by y.StudentID ORDER BY y.AcademicYear,y.SemesterName) / sum(y.SemesterCreditHours) over ( partition by y.StudentID ORDER BY y.AcademicYear,y.SemesterName),2) AS CGPA
FROM (SELECT vw_student_final_grades.StudentID AS StudentID,vw_student_final_grades.SemesterID AS SemesterID,vw_student_final_grades.SemesterName AS SemesterName,vw_student_final_grades.AcademicYear AS AcademicYear,round(sum(vw_student_final_grades.GradePoint * vw_student_final_grades.CreditHours) / sum(vw_student_final_grades.CreditHours),2) AS SemesterGPA,sum(vw_student_final_grades.GradePoint * vw_student_final_grades.CreditHours) AS QualityPoints,sum(vw_student_final_grades.CreditHours) AS SemesterCreditHours FROM vw_student_final_grades
GROUP BY vw_student_final_grades.StudentID,vw_student_final_grades.SemesterID,vw_student_final_grades.SemesterName,vw_student_final_grades.AcademicYear) y;

-- ---- vw_student_timetable ----
CREATE VIEW vw_student_timetable AS
SELECT
    st.StudentID AS StudentID,
    st.F_Name AS F_Name,
    st.L_Name AS L_Name,
    c.CourseCode AS CourseCode,
    c.CourseName AS CourseName,
    t.DayOfWeek AS DayOfWeek,
    t.StartTime AS StartTime,
    t.EndTime AS EndTime,
    t.Room AS Room
FROM (((enrollment e
JOIN student st ON(e.StudentID = st.StudentID))
JOIN course c ON(e.CourseID = c.CourseID))
JOIN timetable t ON(c.CourseID = t.CourseID));

-- ---- vw_ungraded_submissions ----
CREATE VIEW vw_ungraded_submissions AS
SELECT
    c.LecturerID AS LecturerID,
    c.CourseName AS CourseName,
    a.AssessmentName AS AssessmentName,
    st.F_Name AS F_Name,
    st.L_Name AS L_Name,
    sub.SubmissionID AS SubmissionID,
    sub.SubmissionDate AS SubmissionDate,
    COUNT(*) over ( partition by sub.AssessmentID) AS UngradedCountForThisAssessment
FROM (((submission sub
JOIN assessment a ON(sub.AssessmentID = a.AssessmentID))
JOIN course c ON(a.CourseID = c.CourseID))
JOIN student st ON(sub.StudentID = st.StudentID))
WHERE sub.IsActive = 1 and sub.Score is null;

-- ---- vw_upcoming_deadlines_ranked ----
CREATE VIEW vw_upcoming_deadlines_ranked AS
SELECT
    c.CourseID AS CourseID,
    c.CourseName AS CourseName,
    a.AssessmentName AS AssessmentName,
    a.DueDate AS DueDate,
    to_days(a.DueDate) - to_days(curdate()) AS DaysRemaining,
    rank() over ( partition by a.CourseID ORDER BY a.DueDate) AS DeadlineRankInCourse
FROM (assessment a
JOIN course c ON(a.CourseID = c.CourseID))
WHERE a.DueDate >= curdate();

-- ============================================================================
-- 3. FUNCTIONS
-- ============================================================================

DELIMITER //

-- ---- fn_attendance_rate  ----
DROP FUNCTION IF EXISTS fn_attendance_rate //
CREATE FUNCTION fn_attendance_rate(p_StudentID VARCHAR(20),
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

-- ---- fn_calculate_final_grade  ----
DROP FUNCTION IF EXISTS fn_calculate_final_grade //
CREATE FUNCTION fn_calculate_final_grade(p_StudentID VARCHAR(20), p_CourseID VARCHAR(20)) RETURNS decimal(5,2)
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

fn_calculate_final_grade()


-- ============================================================================
-- 4. PROCEDURES
-- ============================================================================

DELIMITER //

-- ---- sp_change_password  ----
DROP PROCEDURE IF EXISTS sp_change_password //
CREATE PROCEDURE sp_change_password(
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

-- ---- sp_create_admin  ----
DROP PROCEDURE IF EXISTS sp_create_admin //
CREATE PROCEDURE sp_create_admin(
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

-- ---- sp_create_assessment  ----
DROP PROCEDURE IF EXISTS sp_create_assessment //
CREATE PROCEDURE sp_create_assessment(
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

-- ---- sp_create_lecturer  ----
DROP PROCEDURE IF EXISTS sp_create_lecturer //
CREATE PROCEDURE sp_create_lecturer(
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

-- ---- sp_create_student  ----
DROP PROCEDURE IF EXISTS sp_create_student //
CREATE PROCEDURE sp_create_student(
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

-- ---- sp_deactivate_user  ----
DROP PROCEDURE IF EXISTS sp_deactivate_user //
CREATE PROCEDURE sp_deactivate_user(IN p_UserID VARCHAR(20))
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM APP_USER WHERE UserID = p_UserID AND IsActive = TRUE;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found or already inactive.';
    ELSE
        UPDATE APP_USER SET IsActive = FALSE WHERE UserID = p_UserID;
    END IF;
END //

-- ---- sp_delete_attendance  ----
DROP PROCEDURE IF EXISTS sp_delete_attendance //
CREATE PROCEDURE sp_delete_attendance(IN p_AttendanceID VARCHAR(20))
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM ATTENDANCE WHERE AttendanceID = p_AttendanceID;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Attendance record not found.';
    ELSE
        DELETE FROM ATTENDANCE WHERE AttendanceID = p_AttendanceID;
    END IF;
END //

-- ---- sp_delete_submission  ----
DROP PROCEDURE IF EXISTS sp_delete_submission //
CREATE PROCEDURE sp_delete_submission(IN p_SubmissionID VARCHAR(20))
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM SUBMISSION WHERE SubmissionID = p_SubmissionID AND IsActive = TRUE;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Submission not found or already inactive.';
    ELSE
        UPDATE SUBMISSION SET IsActive = FALSE WHERE SubmissionID = p_SubmissionID;
    END IF;
END //

-- ---- sp_enroll_student  ----
DROP PROCEDURE IF EXISTS sp_enroll_student //
CREATE PROCEDURE sp_enroll_student(
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

-- ---- sp_generate_transcript  ----
DROP PROCEDURE IF EXISTS sp_generate_transcript //
CREATE PROCEDURE sp_generate_transcript(IN p_StudentID VARCHAR(20))
BEGIN
    SELECT F_Name, L_Name, SemesterName, AcademicYear, CourseID, CourseName, FinalGradePercent, LetterGrade
    FROM VW_STUDENT_FINAL_GRADES
    WHERE StudentID = p_StudentID
    ORDER BY AcademicYear, SemesterName;
END //

-- ---- sp_mark_attendance  ----
DROP PROCEDURE IF EXISTS sp_mark_attendance //
CREATE PROCEDURE sp_mark_attendance(
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

-- ---- sp_reassign_course_lecturer  ----
DROP PROCEDURE IF EXISTS sp_reassign_course_lecturer //
CREATE PROCEDURE sp_reassign_course_lecturer(
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

-- ---- sp_record_grade  ----
DROP PROCEDURE IF EXISTS sp_record_grade //
CREATE PROCEDURE sp_record_grade(
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

-- ---- sp_resubmit_assessment  ----
DROP PROCEDURE IF EXISTS sp_resubmit_assessment //
CREATE PROCEDURE sp_resubmit_assessment(
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

-- ---- sp_submit_assessment  ----
DROP PROCEDURE IF EXISTS sp_submit_assessment //
CREATE PROCEDURE sp_submit_assessment(
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

-- ---- sp_unenroll_student  ----
DROP PROCEDURE IF EXISTS sp_unenroll_student //
CREATE PROCEDURE sp_unenroll_student(
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

-- ---- sp_update_assessment  ----
DROP PROCEDURE IF EXISTS sp_update_assessment //
CREATE PROCEDURE sp_update_assessment(
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

-- ---- sp_update_attendance_status  ----
DROP PROCEDURE IF EXISTS sp_update_attendance_status //
CREATE PROCEDURE sp_update_attendance_status(
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

-- ---- sp_update_timetable  ----
DROP PROCEDURE IF EXISTS sp_update_timetable //
CREATE PROCEDURE sp_update_timetable(
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
-- 5. TRIGGERS
-- ============================================================================

DELIMITER //

-- ---- trg_log_score_change ----
DROP TRIGGER IF EXISTS trg_log_score_change //
CREATE TRIGGER trg_log_score_change
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
CREATE TRIGGER trg_prevent_duplicate_attendance
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
CREATE TRIGGER trg_validate_submission_score
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



-- ---- student_role ----
GRANT USAGE ON *.* TO student_role;
GRANT SELECT ON * TO student_role;
GRANT SELECT ON vw_student_gpa TO student_role;
GRANT SELECT ON vw_course_grades TO student_role;
GRANT SELECT ON vw_upcoming_deadlines_ranked TO student_role;
GRANT SELECT ON vw_below_class_average TO student_role;
GRANT SELECT ON vw_student_final_grades TO student_role;
GRANT EXECUTE ON PROCEDURE sp_unenroll_student TO student_role;
GRANT EXECUTE ON PROCEDURE sp_resubmit_assessment TO student_role;
GRANT EXECUTE ON PROCEDURE sp_change_password TO student_role;
GRANT EXECUTE ON PROCEDURE sp_generate_transcript TO student_role;
GRANT EXECUTE ON PROCEDURE sp_submit_assessment TO student_role;

-- ---- lecturer_role ----
GRANT USAGE ON *.* TO lecturer_role;
GRANT SELECT ON * TO lecturer_role;
GRANT INSERT, UPDATE ON attendance TO lecturer_role;
GRANT INSERT, UPDATE ON submission TO lecturer_role;
GRANT INSERT, UPDATE ON assessment TO lecturer_role;
GRANT SELECT ON vw_ungraded_submissions TO lecturer_role;
GRANT SELECT ON vw_course_score_ranking TO lecturer_role;
GRANT SELECT ON vw_late_submissions TO lecturer_role;
GRANT SELECT ON vw_course_grades TO lecturer_role;
GRANT SELECT ON vw_upcoming_deadlines_ranked TO lecturer_role;
GRANT EXECUTE ON PROCEDURE sp_record_grade TO lecturer_role;
GRANT EXECUTE ON PROCEDURE sp_update_assessment TO lecturer_role;
GRANT EXECUTE ON PROCEDURE sp_create_assessment TO lecturer_role;
GRANT EXECUTE ON PROCEDURE sp_mark_attendance TO lecturer_role;
GRANT EXECUTE ON PROCEDURE sp_change_password TO lecturer_role;
GRANT EXECUTE ON PROCEDURE sp_update_attendance_status TO lecturer_role;

-- ---- admin_role ----
GRANT ALL PRIVILEGES ON * TO admin_role;
GRANT SELECT ON vw_late_submissions TO admin_role;
GRANT SELECT ON vw_courses_without_assessments TO admin_role;
GRANT SELECT ON vw_student_gpa TO admin_role;
GRANT SELECT ON vw_never_absent_students TO admin_role;
GRANT SELECT ON vw_course_performance_ranking TO admin_role;
GRANT SELECT ON vw_course_score_ranking TO admin_role;
GRANT SELECT ON vw_course_enrollment_ranking TO admin_role;
GRANT EXECUTE ON PROCEDURE sp_change_password TO admin_role;
GRANT EXECUTE ON PROCEDURE sp_unenroll_student TO admin_role;
GRANT EXECUTE ON PROCEDURE sp_update_timetable TO admin_role;
GRANT EXECUTE ON PROCEDURE sp_delete_submission TO admin_role;
GRANT EXECUTE ON PROCEDURE sp_reassign_course_lecturer TO admin_role;
GRANT EXECUTE ON PROCEDURE sp_deactivate_user TO admin_role;
GRANT EXECUTE ON PROCEDURE sp_delete_attendance TO admin_role;

FLUSH PRIVILEGES;



-- IMPORTANT SQL QUERIES--
-- 1. SHOWING STUENTS AND THIER COURSES --
Select 
s.StudentID,
s.F_name,s.L_name,
c.courseID,c.coursename
from student s
join enrollment e on
e.studentID = s.studentID
join course c on 
e.courseid = c.courseid;



-- 2. Aggregate query — Student ranking --
 SELECT 
 st.StudentID,
 st.F_name,
 st.L_name,
 Round(AVG(SUB.Score/ass.maxScore* 100),2) as Average_Score
 from student st
 join submission sub on 
 sub.studentId= st.studentId
 join assessment ass on 
 ass.assessmentid = sub.assessmentid
 GROUP BY
    st.StudentID,
    st.F_Name,
    st.L_Name
order by average_score desc;
    

-- 3. Attendance query --
SELECT 
st.StudentID,
st.F_name,
st.L_name,
c.courseName,
count(*) as TotalSession,
SUM(case when att.status = "Present" then 1 else 0 End) as Present,
SUM( case when att.Status = "Late" then 1 else 0 End) as late,
Sum(case when att.status = "Absent" then 1 else 0 End) as Absent

from Attendance att 
join Student st on
att.studentid=st.studentid
join Timetable tt on 
tt.timetableid = att.timetableid
join Course c on
c.courseid = tt.courseid
group by 
st.StudentID,
st.F_name,
st.L_name,
c.Courseid,
c.courseName;

SHOW FULL TABLES
WHERE TABLE_TYPE = 'VIEW';


SELECT *
FROM VW_STUDENT_TIMETABLE
WHERE StudentID = 'S001';

SELECT * FROM VW_STUDENT_FINAL_GRADES
WHERE STUDENTID = "";

select * from vw_ungraded_submissions;

-- Saved Procedure --
CALL sp_generate_transcript('S001');

-- Function --
SELECT fn_calculate_final_grade('S001', 'C001') AS FinalGrade;
select fn_attendance_rate("S001","C001") AS AttendaceRate;


-- Triggers --
SHOW TRIGGERS;

-- Should give error for duplicate entry --
INSERT INTO ATTENDANCE
(AttendanceID, StudentID, TimetableID, AttendanceDate, Status)
VALUES
('ATT001', 'S001', 'T001', '2026-09-08', 'Present');

-- Should prevent entering score above assessment max score 
INSERT INTO SUBMISSION
(SubmissionID, AssessmentID, StudentID, SubmissionDate, Score)
VALUES
('SU999', 'AS0003', 'S001', CURDATE(), 999.00);

select * from student;































