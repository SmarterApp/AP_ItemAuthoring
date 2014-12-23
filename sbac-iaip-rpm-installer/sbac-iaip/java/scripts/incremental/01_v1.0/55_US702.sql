ALTER TABLE `cdesbac`.`stat_administration`
DROP FOREIGN KEY `FK_sas`;

ALTER TABLE `cdesbac`.`stat_administration`
DROP `sa_timestamp`,  DROP `sa_comment`, DROP `ib_id`, DROP `sa_admin_date`, DROP `sas_id`;

ALTER TABLE `cdesbac`.`stat_administration` 
CHANGE COLUMN `sa_identifier` `sa_administration` VARCHAR(255) NOT NULL;

CREATE TABLE IF NOT EXISTS `stat_import_identifier` (
  `sii_id` int(10) NOT NULL AUTO_INCREMENT,
  `sii_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sii_identifier` varchar(30) NOT NULL,
  `sii_comment` varchar(250) DEFAULT NULL,
  `ib_id` int(10) NOT NULL,
  `sii_admin_date` date DEFAULT NULL,
  `sas_id` int(10) DEFAULT NULL,
  PRIMARY KEY (`sii_id`),
  KEY `FK_sas` (`sas_id`),
  CONSTRAINT `FK_sas` FOREIGN KEY (`sas_id`) REFERENCES `stat_administration_status` (`sas_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

CREATE TABLE `stat_identifier_admin` (
  `sia_id` int(10) NOT NULL AUTO_INCREMENT,
  `sii_id` int(10) NOT NULL,
  `sa_id` int(10) NOT NULL,
  PRIMARY KEY (`sia_id`),
  KEY `fk_sii_id` (`sii_id`),
  KEY `fk_sa_id` (`sa_id`),
  CONSTRAINT `fk_sii_id` FOREIGN KEY (`sii_id`) REFERENCES `stat_import_identifier` (`sii_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sa_id` FOREIGN KEY (`sa_id`) REFERENCES `stat_administration` (`sa_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=183 DEFAULT CHARSET=latin1;