CREATE TABLE IF NOT EXISTS `item_pkg_format` (
  `ipf_id` int(10) NOT NULL,
  `ipf_name` varchar(10) default NULL,
  `ipf_description` varchar(255) default NULL,
  PRIMARY KEY  (`ipf_id`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `external_content_metadata` (
  `ecm_id` int(10) NOT NULL auto_increment,
  `i_id` int(10) unsigned NULL,
  `p_id` int(10) unsigned NULL,
  `ecm_content_type` varchar(255) NOT NULL,
  `ecm_content_data` text NULL,
  PRIMARY KEY  (`ecm_id`),
  CONSTRAINT `fk_ecm_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ecm_p_id` FOREIGN KEY (`p_id`) REFERENCES `passage` (`p_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `content_external_attribute` (
  `cea_id` int(10) NOT NULL auto_increment,
  `i_id` int(10) unsigned NULL,
  `p_id` int(10) unsigned NULL,
  `cea_external_id` varchar(256) NULL,
  `cea_format` varchar(10) NULL,
  PRIMARY KEY  (`cea_id`),
  CONSTRAINT `fk_cea_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cea_p_id` FOREIGN KEY (`p_id`) REFERENCES `passage` (`p_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `content_attachment` (
  `ca_id` int(10) NOT NULL auto_increment,
  `i_id` int(10) unsigned NULL,
  `p_id` int(10) unsigned NULL,
  `ca_type` varchar(30) NOT NULL,
  `ca_filename` varchar(60) NULL,
  `ca_source_url` varchar(200) NULL,
  PRIMARY KEY  (`ca_id`),
  CONSTRAINT `fk_ca_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ca_p_id` FOREIGN KEY (`p_id`) REFERENCES `passage` (`p_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

ALTER TABLE item_move_monitor ADD COLUMN `ipf_id` int(10) null;
ALTER TABLE item_move_monitor ADD CONSTRAINT `fk_imm_ipf_id` FOREIGN KEY (`ipf_id`) REFERENCES `item_pkg_format` (`ipf_id`) ON DELETE CASCADE;