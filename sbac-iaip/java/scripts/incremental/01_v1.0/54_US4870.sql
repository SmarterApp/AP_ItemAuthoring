CREATE TABLE IF NOT EXISTS `item_standard` (
  `isd_id` int(10) NOT NULL auto_increment,
  `i_id` int(10) UNSIGNED NULL,
  `isd_standard` TEXT NULL,
  PRIMARY KEY  (`isd_id`),
  CONSTRAINT `fk_isd_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

ALTER TABLE item ADD COLUMN `i_primary_standard` TEXT NULL;