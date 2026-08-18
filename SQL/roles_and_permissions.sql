-- SLMS database roles and grants.
-- Run after tables, views, procedures/functions, and triggers.

CREATE ROLE IF NOT EXISTS student_role;
CREATE ROLE IF NOT EXISTS lecturer_role;
CREATE ROLE IF NOT EXISTS admin_role;

USE slms;

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
