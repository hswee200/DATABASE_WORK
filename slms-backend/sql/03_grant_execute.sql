-- The schema created the roles with SELECT (plus INSERT/UPDATE on three tables
-- for lecturers) but never EXECUTE, so CALL fails under every role except
-- admin_role. Granted per-procedure rather than schema-wide to keep least
-- privilege: each role gets exactly the routines its endpoints need.
--
-- Must run as root@localhost.

GRANT EXECUTE ON PROCEDURE SLMS.sp_generate_transcript TO student_role;
GRANT EXECUTE ON PROCEDURE SLMS.sp_record_grade        TO lecturer_role;

FLUSH PRIVILEGES;

-- Deliberately omitted:
--   * admin_role gets nothing new — GRANT ALL PRIVILEGES ON slms.* already
--     includes EXECUTE on every routine (verified by calling them under it).
--   * sp_enroll_student is not granted to student_role — enrolment is
--     admin-driven, so student_role stays read-only as the schema intended.
--   * fn_calculate_final_grade / fn_attendance_rate are not granted — no
--     planned endpoint calls them inline, since the views compute their own
--     values. Grant if and when an endpoint actually needs them.
