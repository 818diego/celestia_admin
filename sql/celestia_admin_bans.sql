CREATE TABLE IF NOT EXISTS `celestia_admin_bans` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(80) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `banned_by_identifier` VARCHAR(80) NOT NULL,
    `banned_by_name` VARCHAR(100) NOT NULL,
    `banned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `unbanned_by_identifier` VARCHAR(80) NULL,
    `unbanned_by_name` VARCHAR(100) NULL,
    `unbanned_at` TIMESTAMP NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_identifier_active` (`identifier`, `active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
