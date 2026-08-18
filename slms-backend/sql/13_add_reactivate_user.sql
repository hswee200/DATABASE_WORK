-- Adds sp_reactivate_user, the mirror of sp_deactivate_user, and does a
-- one-time bulk reactivation of every account currently deactivated (there
-- is no audit trail column on APP_USER to worry about preserving - see
-- IsActive tinyint(1) DEFAULT 1, no "DeactivatedAt"/"DeactivatedBy").
--
-- Must run as root@localhost, matching the DEFINER convention already used
-- by every routine added in sql/11_auto_generate_ids.sql.

USE slms;

DELIMITER //

DROP PROCEDURE IF EXISTS sp_reactivate_user //

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_reactivate_user(IN p_UserID VARCHAR(20))
BEGIN
    DECLARE existing_count INT;
    SELECT COUNT(*) INTO existing_count FROM APP_USER WHERE UserID = p_UserID AND IsActive = FALSE;
    IF existing_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found or already active.';
    ELSE
        UPDATE APP_USER SET IsActive = TRUE WHERE UserID = p_UserID;
    END IF;
END //

DELIMITER ;

GRANT EXECUTE ON PROCEDURE slms.sp_reactivate_user TO admin_role;

FLUSH PRIVILEGES;

-- One-time fix: reactivate every account currently deactivated (this
-- includes L001, deactivated during earlier-session testing, and any
-- other accounts deactivated along the way).
UPDATE APP_USER SET IsActive = TRUE WHERE IsActive = FALSE;
