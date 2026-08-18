-- Cleanup after browser verification of the name-search/auto-ID feature.
-- Removes the synthetic records created purely for testing and restores the
-- one seed row that was soft-deleted during the Corrections test.

USE SLMS;

-- 1. Test student created via Create User (S0051 / U0231), deactivated during
--    the Deactivate User test. Remove entirely rather than reactivate, since
--    it never existed in the seed data.
DELETE FROM STUDENT WHERE StudentID = 'S0051';
DELETE FROM APP_USER WHERE UserID = 'U0231';

-- 2. Test assessment created on CS003 (AS0244 "Verify Assessment").
DELETE FROM ASSESSMENT WHERE AssessmentID = 'AS0244';

-- 3. Restore Kojo Adjei's Project 1 submission on Intro to Programming
--    (SUB00091), soft-deleted during the Corrections delete-submission test.
UPDATE SUBMISSION SET IsActive = TRUE WHERE SubmissionID = 'SUB00091';

-- Note: the test attendance mark (ATT02322, Kojo Adjei / Intro to
-- Programming / 2026-08-16) was already hard-deleted via the Corrections
-- delete-attendance test, so no cleanup is needed for it.
-- Note: CS001's lecturer was reassigned to Efua Danso and back to Kofi
-- Boateng during the Reassign Lecturer test, already at baseline.
