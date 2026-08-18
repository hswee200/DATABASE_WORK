-- ============================================================================
-- SLMS -- LIVE DATABASE SCHEMA SNAPSHOT
-- Generated 2026-08-15 directly from the running MariaDB instance
-- via SHOW CREATE TABLE / VIEW / PROCEDURE / FUNCTION / TRIGGER against
-- information_schema.{TABLES,VIEWS,ROUTINES,TRIGGERS} (schema = 'slms').
--
-- This supersedes the previous snapshot: two migrations landed since then
-- (sql/09_assessment_weights_and_gpa.sql, sql/10_fix_final_grade_percent_scale.sql)
-- adding ASSESSMENT.AssessmentCategory, vw_course_grades, vw_student_gpa, and
-- reworking vw_student_final_grades onto weighted grading + GPA. As before,
-- this is NOT a re-derivation of SLMS.sql or the sql/0N_*.sql migration files
-- - it is what information_schema reports RIGHT NOW, pulled live, not what any
-- .sql file on disk claims. DEFINER drift between root@localhost and
-- vincentchanayire@localhost (see the comment on each routine below) is direct
-- evidence several objects were changed outside the numbered migration
-- sequence at various points.
--
-- Running this file top-to-bottom against an empty schema reproduces the
-- live structure. It is a snapshot for reference/diffing, not a new
-- migration step -- do not add it to the sql/0N_*.sql sequence.
-- ============================================================================

USE slms;

-- ============================================================================
-- 1. TABLES
-- ============================================================================

-- ---- Admin_USER ----
CREATE TABLE `Admin_USER` (
  `AdminID` varchar(20) NOT NULL,
  `F_Name` varchar(30) NOT NULL,
  `L_Name` varchar(30) NOT NULL,
  `UserID` varchar(20) NOT NULL,
  `DateOfBirth` date DEFAULT NULL,
  PRIMARY KEY (`AdminID`),
  UNIQUE KEY `UserID` (`UserID`),
  CONSTRAINT `1` FOREIGN KEY (`UserID`) REFERENCES `APP_USER` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- APP_USER ----
CREATE TABLE `APP_USER` (
  `UserID` varchar(20) NOT NULL,
  `Username` varchar(20) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `PasswordHash` varchar(255) NOT NULL,
  `RoleID` int(11) NOT NULL,
  `IsActive` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`UserID`),
  UNIQUE KEY `Username` (`Username`),
  UNIQUE KEY `Email` (`Email`),
  KEY `RoleID` (`RoleID`),
  CONSTRAINT `1` FOREIGN KEY (`RoleID`) REFERENCES `User_Role` (`RoleID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- ASSESSMENT ----
CREATE TABLE `ASSESSMENT` (
  `AssessmentID` varchar(20) NOT NULL,
  `CourseID` varchar(20) NOT NULL,
  `AssessmentType` varchar(50) NOT NULL,
  `AssessmentName` varchar(100) NOT NULL,
  `MaxScore` decimal(5,2) NOT NULL,
  `DueDate` date DEFAULT NULL,
  `AssessmentCategory` enum('Regular','Midsem','Final') NOT NULL DEFAULT 'Regular',
  PRIMARY KEY (`AssessmentID`),
  KEY `CourseID` (`CourseID`),
  CONSTRAINT `1` FOREIGN KEY (`CourseID`) REFERENCES `COURSE` (`CourseID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- ATTENDANCE ----
CREATE TABLE `ATTENDANCE` (
  `AttendanceID` varchar(20) NOT NULL,
  `StudentID` varchar(20) NOT NULL,
  `TimetableID` varchar(20) NOT NULL,
  `AttendanceDate` date NOT NULL,
  `Status` varchar(10) NOT NULL CHECK (`Status` in ('Present','Absent','Late')),
  PRIMARY KEY (`AttendanceID`),
  KEY `StudentID` (`StudentID`),
  KEY `TimetableID` (`TimetableID`),
  CONSTRAINT `1` FOREIGN KEY (`StudentID`) REFERENCES `STUDENT` (`StudentID`),
  CONSTRAINT `2` FOREIGN KEY (`TimetableID`) REFERENCES `TIMETABLE` (`TimetableID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- COURSE ----
CREATE TABLE `COURSE` (
  `CourseID` varchar(20) NOT NULL,
  `CourseName` varchar(100) NOT NULL,
  `CourseCode` varchar(20) NOT NULL,
  `CreditHours` int(11) NOT NULL,
  `LecturerID` varchar(20) NOT NULL,
  `SemesterID` varchar(20) NOT NULL,
  PRIMARY KEY (`CourseID`),
  UNIQUE KEY `CourseCode` (`CourseCode`),
  KEY `LecturerID` (`LecturerID`),
  KEY `SemesterID` (`SemesterID`),
  CONSTRAINT `1` FOREIGN KEY (`LecturerID`) REFERENCES `Lecturer` (`LecturerID`),
  CONSTRAINT `2` FOREIGN KEY (`SemesterID`) REFERENCES `Semester` (`SemesterID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- ENROLLMENT ----
CREATE TABLE `ENROLLMENT` (
  `EnrollmentID` varchar(20) NOT NULL,
  `StudentID` varchar(20) NOT NULL,
  `CourseID` varchar(20) NOT NULL,
  `EnrollmentDate` date NOT NULL,
  PRIMARY KEY (`EnrollmentID`),
  KEY `StudentID` (`StudentID`),
  KEY `CourseID` (`CourseID`),
  CONSTRAINT `1` FOREIGN KEY (`StudentID`) REFERENCES `STUDENT` (`StudentID`),
  CONSTRAINT `2` FOREIGN KEY (`CourseID`) REFERENCES `COURSE` (`CourseID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- Lecturer ----
CREATE TABLE `Lecturer` (
  `LecturerID` varchar(20) NOT NULL,
  `F_Name` varchar(30) NOT NULL,
  `L_Name` varchar(30) NOT NULL,
  `UserID` varchar(20) NOT NULL,
  `DateOfBirth` date DEFAULT NULL,
  PRIMARY KEY (`LecturerID`),
  UNIQUE KEY `UserID` (`UserID`),
  CONSTRAINT `1` FOREIGN KEY (`UserID`) REFERENCES `APP_USER` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- SEMESTER ----
CREATE TABLE `SEMESTER` (
  `SemesterID` varchar(20) NOT NULL,
  `SemesterName` varchar(60) NOT NULL,
  `AcademicYear` varchar(20) NOT NULL,
  `StartDate` date DEFAULT NULL,
  `EndDate` date DEFAULT NULL,
  PRIMARY KEY (`SemesterID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- STUDENT ----
CREATE TABLE `STUDENT` (
  `StudentID` varchar(20) NOT NULL,
  `F_Name` varchar(30) NOT NULL,
  `L_Name` varchar(30) NOT NULL,
  `UserID` varchar(20) NOT NULL,
  `DateOfBirth` date DEFAULT NULL,
  PRIMARY KEY (`StudentID`),
  UNIQUE KEY `UserID` (`UserID`),
  CONSTRAINT `1` FOREIGN KEY (`UserID`) REFERENCES `APP_USER` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- SUBMISSION ----
CREATE TABLE `SUBMISSION` (
  `SubmissionID` varchar(20) NOT NULL,
  `AssessmentID` varchar(20) NOT NULL,
  `StudentID` varchar(20) NOT NULL,
  `SubmissionDate` date DEFAULT NULL,
  `Score` decimal(5,2) DEFAULT NULL,
  `IsActive` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`SubmissionID`),
  KEY `AssessmentID` (`AssessmentID`),
  KEY `StudentID` (`StudentID`),
  CONSTRAINT `1` FOREIGN KEY (`AssessmentID`) REFERENCES `ASSESSMENT` (`AssessmentID`),
  CONSTRAINT `2` FOREIGN KEY (`StudentID`) REFERENCES `STUDENT` (`StudentID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- SUBMISSION_AUDIT_LOG ----
CREATE TABLE `SUBMISSION_AUDIT_LOG` (
  `LogID` int(11) NOT NULL AUTO_INCREMENT,
  `SubmissionID` varchar(20) NOT NULL,
  `OldScore` decimal(5,2) DEFAULT NULL,
  `NewScore` decimal(5,2) DEFAULT NULL,
  `ChangedAt` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`LogID`),
  KEY `SubmissionID` (`SubmissionID`),
  CONSTRAINT `1` FOREIGN KEY (`SubmissionID`) REFERENCES `SUBMISSION` (`SubmissionID`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- TIMETABLE ----
CREATE TABLE `TIMETABLE` (
  `TimetableID` varchar(20) NOT NULL,
  `CourseID` varchar(20) NOT NULL,
  `DayOfWeek` varchar(10) NOT NULL,
  `StartTime` time NOT NULL,
  `EndTime` time NOT NULL,
  `Room` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`TimetableID`),
  KEY `CourseID` (`CourseID`),
  CONSTRAINT `1` FOREIGN KEY (`CourseID`) REFERENCES `COURSE` (`CourseID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---- User_Role ----
CREATE TABLE `User_Role` (
  `RoleID` int(11) NOT NULL AUTO_INCREMENT,
  `RoleName` varchar(20) NOT NULL,
  PRIMARY KEY (`RoleID`),
  UNIQUE KEY `RoleName` (`RoleName`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ============================================================================
-- 2. VIEWS
-- ============================================================================

-- ---- vw_assessment_status ----
CREATE ALGORITHM=UNDEFINED DEFINER=`vincentchanayire`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_assessment_status` AS select `e`.`StudentID` AS `StudentID`,`a`.`AssessmentID` AS `AssessmentID`,`a`.`AssessmentName` AS `AssessmentName`,`a`.`CourseID` AS `CourseID`,`a`.`DueDate` AS `DueDate`,`sub`.`SubmissionID` AS `SubmissionID`,case when `sub`.`SubmissionID` is not null then 'Submitted' when `a`.`DueDate` < curdate() then 'Past-Due' else 'Upcoming' end AS `Status` from ((`slms`.`enrollment` `e` join `slms`.`assessment` `a` on(`e`.`CourseID` = `a`.`CourseID`)) left join `slms`.`submission` `sub` on(`sub`.`AssessmentID` = `a`.`AssessmentID` and `sub`.`StudentID` = `e`.`StudentID` and `sub`.`IsActive` = 1));

-- ---- vw_attendance_summary ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_attendance_summary` AS select `st`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name`,`c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,sum(case when `att`.`Status` = 'Present' then 1 else 0 end) AS `TimesPresent`,sum(case when `att`.`Status` = 'Absent' then 1 else 0 end) AS `TimesAbsent`,sum(case when `att`.`Status` = 'Late' then 1 else 0 end) AS `TimesLate`,count(0) AS `TotalSessions`,round(sum(case when `att`.`Status` = 'Present' then 1 else 0 end) * 100.0 / count(0),2) AS `AttendanceRate` from (((`slms`.`attendance` `att` join `slms`.`timetable` `t` on(`att`.`TimetableID` = `t`.`TimetableID`)) join `slms`.`course` `c` on(`t`.`CourseID` = `c`.`CourseID`)) join `slms`.`student` `st` on(`att`.`StudentID` = `st`.`StudentID`)) group by `st`.`StudentID`,`st`.`F_Name`,`st`.`L_Name`,`c`.`CourseID`,`c`.`CourseName`;

-- ---- vw_below_class_average ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_below_class_average` AS select `y`.`CourseID` AS `CourseID`,`y`.`CourseName` AS `CourseName`,`y`.`StudentID` AS `StudentID`,`y`.`F_Name` AS `F_Name`,`y`.`L_Name` AS `L_Name`,`y`.`StudentAvg` AS `StudentAvg`,avg(`y`.`StudentAvg`) over ( partition by `y`.`CourseID`) AS `ClassAvg` from (select `c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,`st`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name`,avg(`sub`.`Score`) AS `StudentAvg` from (((`slms`.`submission` `sub` join `slms`.`assessment` `a` on(`sub`.`AssessmentID` = `a`.`AssessmentID`)) join `slms`.`course` `c` on(`a`.`CourseID` = `c`.`CourseID`)) join `slms`.`student` `st` on(`sub`.`StudentID` = `st`.`StudentID`)) where `sub`.`IsActive` = 1 group by `c`.`CourseID`,`c`.`CourseName`,`st`.`StudentID`,`st`.`F_Name`,`st`.`L_Name`) `y`;

-- ---- vw_courses_without_assessments ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_courses_without_assessments` AS select distinct `c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,`c`.`CourseCode` AS `CourseCode` from (`slms`.`course` `c` left join `slms`.`assessment` `a` on(`c`.`CourseID` = `a`.`CourseID`)) where `a`.`AssessmentID` is null;

-- ---- vw_course_enrollment_ranking ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_course_enrollment_ranking` AS select `c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,count(`e`.`StudentID`) AS `EnrolledStudents`,rank() over ( order by count(`e`.`StudentID`) desc) AS `EnrollmentRank` from (`slms`.`course` `c` join `slms`.`enrollment` `e` on(`c`.`CourseID` = `e`.`CourseID`)) group by `c`.`CourseID`,`c`.`CourseName`;

-- ---- vw_course_grades ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_course_grades` AS select `e`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name`,`a`.`CourseID` AS `CourseID`,`a`.`AssessmentID` AS `AssessmentID`,`a`.`AssessmentName` AS `AssessmentName`,`a`.`AssessmentCategory` AS `AssessmentCategory`,`a`.`MaxScore` AS `MaxScore`,`sub`.`Score` AS `Score`,`sub`.`SubmissionID` AS `SubmissionID`,case `a`.`AssessmentCategory` when 'Midsem' then 20 when 'Final' then 40 else (100 - if(exists(select 1 from `slms`.`assessment` `a2` where `a2`.`CourseID` = `a`.`CourseID` and `a2`.`AssessmentCategory` = 'Midsem' limit 1),20,0) - if(exists(select 1 from `slms`.`assessment` `a2` where `a2`.`CourseID` = `a`.`CourseID` and `a2`.`AssessmentCategory` = 'Final' limit 1),40,0)) / nullif((select count(0) from `slms`.`assessment` `a3` where `a3`.`CourseID` = `a`.`CourseID` and `a3`.`AssessmentCategory` = 'Regular'),0) end AS `Weight` from (((`slms`.`assessment` `a` join `slms`.`enrollment` `e` on(`e`.`CourseID` = `a`.`CourseID`)) join `slms`.`student` `st` on(`st`.`StudentID` = `e`.`StudentID`)) left join `slms`.`submission` `sub` on(`sub`.`AssessmentID` = `a`.`AssessmentID` and `sub`.`StudentID` = `e`.`StudentID` and `sub`.`IsActive` = 1));

-- ---- vw_course_performance_ranking ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_course_performance_ranking` AS select `c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,round(avg(`sub`.`Score` * 100.0 / `a`.`MaxScore`),1) AS `AvgScorePct`,rank() over ( order by avg(`sub`.`Score` * 100.0 / `a`.`MaxScore`)) AS `LowPerformanceRank` from ((`slms`.`submission` `sub` join `slms`.`assessment` `a` on(`sub`.`AssessmentID` = `a`.`AssessmentID`)) join `slms`.`course` `c` on(`a`.`CourseID` = `c`.`CourseID`)) where `sub`.`IsActive` = 1 group by `c`.`CourseID`,`c`.`CourseName`;

-- ---- vw_course_roster ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_course_roster` AS select `c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,`l`.`F_Name` AS `LecturerFirstName`,`l`.`L_Name` AS `LecturerLastName`,`st`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `StudentFirstName`,`st`.`L_Name` AS `StudentLastName`,`e`.`EnrollmentDate` AS `EnrollmentDate` from (((`slms`.`enrollment` `e` join `slms`.`course` `c` on(`e`.`CourseID` = `c`.`CourseID`)) join `slms`.`lecturer` `l` on(`c`.`LecturerID` = `l`.`LecturerID`)) join `slms`.`student` `st` on(`e`.`StudentID` = `st`.`StudentID`));

-- ---- vw_course_score_ranking ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_course_score_ranking` AS select `c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,`st`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name`,round(avg(`sub`.`Score`),2) AS `AvgScore`,rank() over ( partition by `c`.`CourseID` order by avg(`sub`.`Score`) desc) AS `RankInCourse` from ((((`slms`.`submission` `sub` join `slms`.`assessment` `a` on(`sub`.`AssessmentID` = `a`.`AssessmentID`)) join `slms`.`course` `c` on(`a`.`CourseID` = `c`.`CourseID`)) join `slms`.`student` `st` on(`sub`.`StudentID` = `st`.`StudentID`)) join `slms`.`enrollment` `e` on(`e`.`StudentID` = `st`.`StudentID` and `e`.`CourseID` = `c`.`CourseID`)) where `sub`.`IsActive` = 1 group by `c`.`CourseID`,`c`.`CourseName`,`st`.`StudentID`,`st`.`F_Name`,`st`.`L_Name`;

-- ---- vw_late_submissions ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_late_submissions` AS select `st`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name`,`c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,`a`.`AssessmentName` AS `AssessmentName`,`a`.`DueDate` AS `DueDate`,`sub`.`SubmissionDate` AS `SubmissionDate`,to_days(`sub`.`SubmissionDate`) - to_days(`a`.`DueDate`) AS `DaysLate`,rank() over ( partition by `c`.`CourseID` order by to_days(`sub`.`SubmissionDate`) - to_days(`a`.`DueDate`) desc) AS `LatenessRankInCourse` from (((`slms`.`submission` `sub` join `slms`.`assessment` `a` on(`sub`.`AssessmentID` = `a`.`AssessmentID`)) join `slms`.`course` `c` on(`a`.`CourseID` = `c`.`CourseID`)) join `slms`.`student` `st` on(`sub`.`StudentID` = `st`.`StudentID`)) where `sub`.`IsActive` = 1 and `sub`.`SubmissionDate` > `a`.`DueDate`;

-- ---- vw_lecturer_load ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_lecturer_load` AS select `l`.`LecturerID` AS `LecturerID`,`l`.`F_Name` AS `F_Name`,`l`.`L_Name` AS `L_Name`,count(distinct `c`.`CourseID`) AS `NumCourses`,count(distinct `e`.`StudentID`) AS `NumStudents` from ((`slms`.`lecturer` `l` left join `slms`.`course` `c` on(`l`.`LecturerID` = `c`.`LecturerID`)) left join `slms`.`enrollment` `e` on(`c`.`CourseID` = `e`.`CourseID`)) group by `l`.`LecturerID`;

-- ---- vw_lecturer_timetable ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_lecturer_timetable` AS select `l`.`LecturerID` AS `LecturerID`,`l`.`F_Name` AS `F_Name`,`l`.`L_Name` AS `L_Name`,`c`.`CourseID` AS `CourseID`,`c`.`CourseCode` AS `CourseCode`,`c`.`CourseName` AS `CourseName`,`s`.`SemesterName` AS `SemesterName`,`s`.`AcademicYear` AS `AcademicYear`,`t`.`DayOfWeek` AS `DayOfWeek`,`t`.`StartTime` AS `StartTime`,`t`.`EndTime` AS `EndTime`,`t`.`Room` AS `Room` from (((`slms`.`lecturer` `l` join `slms`.`course` `c` on(`l`.`LecturerID` = `c`.`LecturerID`)) join `slms`.`timetable` `t` on(`c`.`CourseID` = `t`.`CourseID`)) join `slms`.`semester` `s` on(`c`.`SemesterID` = `s`.`SemesterID`));

-- ---- vw_never_absent_students ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_never_absent_students` AS select `st`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name` from `slms`.`student` `st` where exists(select 1 from `slms`.`attendance` `att` where `att`.`StudentID` = `st`.`StudentID` limit 1) and !exists(select 1 from `slms`.`attendance` `att` where `att`.`StudentID` = `st`.`StudentID` and `att`.`Status` = 'Absent' limit 1);

-- ---- vw_student_final_grades ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_student_final_grades` AS select `x`.`StudentID` AS `StudentID`,`x`.`F_Name` AS `F_Name`,`x`.`L_Name` AS `L_Name`,`x`.`SemesterID` AS `SemesterID`,`x`.`SemesterName` AS `SemesterName`,`x`.`AcademicYear` AS `AcademicYear`,`x`.`CourseID` AS `CourseID`,`x`.`CourseName` AS `CourseName`,`x`.`CreditHours` AS `CreditHours`,`x`.`FinalGradePercent` AS `FinalGradePercent`,case when `x`.`FinalGradePercent` >= 90 then 'A+' when `x`.`FinalGradePercent` >= 80 then 'A' when `x`.`FinalGradePercent` >= 70 then 'B' when `x`.`FinalGradePercent` >= 60 then 'C' when `x`.`FinalGradePercent` >= 50 then 'D' else 'F' end AS `LetterGrade`,case when `x`.`FinalGradePercent` >= 80 then 4.0 when `x`.`FinalGradePercent` >= 70 then 3.0 when `x`.`FinalGradePercent` >= 60 then 2.0 when `x`.`FinalGradePercent` >= 50 then 1.0 else 0.0 end AS `GradePoint` from (select `g`.`StudentID` AS `StudentID`,`g`.`F_Name` AS `F_Name`,`g`.`L_Name` AS `L_Name`,`c`.`SemesterID` AS `SemesterID`,`s`.`SemesterName` AS `SemesterName`,`s`.`AcademicYear` AS `AcademicYear`,`c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,`c`.`CreditHours` AS `CreditHours`,round(sum(`g`.`Score` / `g`.`MaxScore` * `g`.`Weight`) / sum(`g`.`Weight`) * 100,2) AS `FinalGradePercent` from ((`slms`.`vw_course_grades` `g` join `slms`.`course` `c` on(`c`.`CourseID` = `g`.`CourseID`)) join `slms`.`semester` `s` on(`c`.`SemesterID` = `s`.`SemesterID`)) where `g`.`Score` is not null group by `g`.`StudentID`,`g`.`F_Name`,`g`.`L_Name`,`c`.`SemesterID`,`s`.`SemesterName`,`s`.`AcademicYear`,`c`.`CourseID`,`c`.`CourseName`,`c`.`CreditHours`) `x`;

-- ---- vw_student_gpa ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_student_gpa` AS select `y`.`StudentID` AS `StudentID`,`y`.`SemesterID` AS `SemesterID`,`y`.`SemesterName` AS `SemesterName`,`y`.`AcademicYear` AS `AcademicYear`,`y`.`SemesterGPA` AS `SemesterGPA`,round(sum(`y`.`QualityPoints`) over ( partition by `y`.`StudentID` order by `y`.`AcademicYear`,`y`.`SemesterName`) / sum(`y`.`SemesterCreditHours`) over ( partition by `y`.`StudentID` order by `y`.`AcademicYear`,`y`.`SemesterName`),2) AS `CGPA` from (select `vw_student_final_grades`.`StudentID` AS `StudentID`,`vw_student_final_grades`.`SemesterID` AS `SemesterID`,`vw_student_final_grades`.`SemesterName` AS `SemesterName`,`vw_student_final_grades`.`AcademicYear` AS `AcademicYear`,round(sum(`vw_student_final_grades`.`GradePoint` * `vw_student_final_grades`.`CreditHours`) / sum(`vw_student_final_grades`.`CreditHours`),2) AS `SemesterGPA`,sum(`vw_student_final_grades`.`GradePoint` * `vw_student_final_grades`.`CreditHours`) AS `QualityPoints`,sum(`vw_student_final_grades`.`CreditHours`) AS `SemesterCreditHours` from `slms`.`vw_student_final_grades` group by `vw_student_final_grades`.`StudentID`,`vw_student_final_grades`.`SemesterID`,`vw_student_final_grades`.`SemesterName`,`vw_student_final_grades`.`AcademicYear`) `y`;

-- ---- vw_student_timetable ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_student_timetable` AS select `st`.`StudentID` AS `StudentID`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name`,`c`.`CourseCode` AS `CourseCode`,`c`.`CourseName` AS `CourseName`,`t`.`DayOfWeek` AS `DayOfWeek`,`t`.`StartTime` AS `StartTime`,`t`.`EndTime` AS `EndTime`,`t`.`Room` AS `Room` from (((`slms`.`enrollment` `e` join `slms`.`student` `st` on(`e`.`StudentID` = `st`.`StudentID`)) join `slms`.`course` `c` on(`e`.`CourseID` = `c`.`CourseID`)) join `slms`.`timetable` `t` on(`c`.`CourseID` = `t`.`CourseID`));

-- ---- vw_ungraded_submissions ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_ungraded_submissions` AS select `c`.`LecturerID` AS `LecturerID`,`c`.`CourseName` AS `CourseName`,`a`.`AssessmentName` AS `AssessmentName`,`st`.`F_Name` AS `F_Name`,`st`.`L_Name` AS `L_Name`,`sub`.`SubmissionID` AS `SubmissionID`,`sub`.`SubmissionDate` AS `SubmissionDate`,count(0) over ( partition by `sub`.`AssessmentID`) AS `UngradedCountForThisAssessment` from (((`slms`.`submission` `sub` join `slms`.`assessment` `a` on(`sub`.`AssessmentID` = `a`.`AssessmentID`)) join `slms`.`course` `c` on(`a`.`CourseID` = `c`.`CourseID`)) join `slms`.`student` `st` on(`sub`.`StudentID` = `st`.`StudentID`)) where `sub`.`IsActive` = 1 and `sub`.`Score` is null;

-- ---- vw_upcoming_deadlines_ranked ----
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `slms`.`vw_upcoming_deadlines_ranked` AS select `c`.`CourseID` AS `CourseID`,`c`.`CourseName` AS `CourseName`,`a`.`AssessmentName` AS `AssessmentName`,`a`.`DueDate` AS `DueDate`,to_days(`a`.`DueDate`) - to_days(curdate()) AS `DaysRemaining`,rank() over ( partition by `a`.`CourseID` order by `a`.`DueDate`) AS `DeadlineRankInCourse` from (`slms`.`assessment` `a` join `slms`.`course` `c` on(`a`.`CourseID` = `c`.`CourseID`)) where `a`.`DueDate` >= curdate();

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
-- 4. PROCEDURES
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
-- 5. TRIGGERS
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

-- ============================================================================
-- APPENDIX: CURRENT ROLE GRANTS (informational -- reflects live SHOW GRANTS)
-- Included because EXECUTE/SELECT privileges are part of what actually makes
-- each object usable; the definitions above are inert without these.
-- ============================================================================

-- ---- student_role ----
GRANT USAGE ON *.* TO `student_role`;
GRANT SELECT ON `slms`.* TO `student_role`;
GRANT SELECT ON `slms`.`vw_student_gpa` TO `student_role`;
GRANT SELECT ON `slms`.`vw_course_grades` TO `student_role`;
GRANT SELECT ON `slms`.`vw_upcoming_deadlines_ranked` TO `student_role`;
GRANT SELECT ON `slms`.`vw_below_class_average` TO `student_role`;
GRANT SELECT ON `slms`.`vw_student_final_grades` TO `student_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_unenroll_student` TO `student_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_resubmit_assessment` TO `student_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_change_password` TO `student_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_generate_transcript` TO `student_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_submit_assessment` TO `student_role`;

-- ---- lecturer_role ----
GRANT USAGE ON *.* TO `lecturer_role`;
GRANT SELECT ON `slms`.* TO `lecturer_role`;
GRANT INSERT, UPDATE ON `slms`.`attendance` TO `lecturer_role`;
GRANT INSERT, UPDATE ON `slms`.`submission` TO `lecturer_role`;
GRANT INSERT, UPDATE ON `slms`.`assessment` TO `lecturer_role`;
GRANT SELECT ON `slms`.`vw_ungraded_submissions` TO `lecturer_role`;
GRANT SELECT ON `slms`.`vw_course_score_ranking` TO `lecturer_role`;
GRANT SELECT ON `slms`.`vw_late_submissions` TO `lecturer_role`;
GRANT SELECT ON `slms`.`vw_course_grades` TO `lecturer_role`;
GRANT SELECT ON `slms`.`vw_upcoming_deadlines_ranked` TO `lecturer_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_record_grade` TO `lecturer_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_update_assessment` TO `lecturer_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_create_assessment` TO `lecturer_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_mark_attendance` TO `lecturer_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_change_password` TO `lecturer_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_update_attendance_status` TO `lecturer_role`;

-- ---- admin_role ----
GRANT ALL PRIVILEGES ON `slms`.* TO `admin_role`;
GRANT SELECT ON `slms`.`vw_late_submissions` TO `admin_role`;
GRANT SELECT ON `slms`.`vw_courses_without_assessments` TO `admin_role`;
GRANT SELECT ON `slms`.`vw_student_gpa` TO `admin_role`;
GRANT SELECT ON `slms`.`vw_never_absent_students` TO `admin_role`;
GRANT SELECT ON `slms`.`vw_course_performance_ranking` TO `admin_role`;
GRANT SELECT ON `slms`.`vw_course_score_ranking` TO `admin_role`;
GRANT SELECT ON `slms`.`vw_course_enrollment_ranking` TO `admin_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_change_password` TO `admin_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_unenroll_student` TO `admin_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_update_timetable` TO `admin_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_delete_submission` TO `admin_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_reassign_course_lecturer` TO `admin_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_deactivate_user` TO `admin_role`;
GRANT EXECUTE ON PROCEDURE `slms`.`sp_delete_attendance` TO `admin_role`;

FLUSH PRIVILEGES;
