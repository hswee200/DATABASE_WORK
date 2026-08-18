-- SLMS table definitions extracted from the live schema snapshot.
-- Run after create_database.sql.
-- The snapshot's table order follows the database export, not foreign-key
-- dependency order. Disable checks only while defining the empty schema.

USE slms;

SET FOREIGN_KEY_CHECKS = 0;

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

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
