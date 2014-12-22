CREATE TABLE IF NOT EXISTS `item_move_type` (
  `imt_id` int(10) NOT NULL,
  `imt_name` varchar(10) default NULL,
  PRIMARY KEY  (`imt_id`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `item_move_status` (
  `ims_id` int(10) NOT NULL,
  `ims_value` varchar(20) default NULL,
  PRIMARY KEY  (`ims_id`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `detail_status_type` (
  `dst_id` int(10) NOT NULL,
  `dst_code` int(5) default NULL,
  `dst_type` varchar(20) default NULL,
  `dst_value` varchar(50) default NULL,
  PRIMARY KEY  (`dst_id`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `item_move_monitor` (
  `imm_id` int(10) NOT NULL auto_increment,
  `ib_id` int(10) unsigned NOT NULL,
  `u_id` int(10) unsigned NOT NULL,
  `imt_id` int(10) NOT NULL,
  `ims_id` int(10) NOT NULL,
  `imm_src` varchar(255) NULL,
  `imm_dst` varchar(255) NULL,
  `imm_file_name` varchar(255) NOT NULL,
  `imm_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`imm_id`),
  CONSTRAINT `fk_imm_ib_id` FOREIGN KEY (`ib_id`) REFERENCES `item_bank` (`ib_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_imm_u_id` FOREIGN KEY (`u_id`) REFERENCES `user` (`u_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_imm_imt_id` FOREIGN KEY (`imt_id`) REFERENCES `item_move_type` (`imt_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_imm_ims_id` FOREIGN KEY (`ims_id`) REFERENCES `item_move_status` (`ims_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `item_move_details` (
  `imd_id` int(10) NOT NULL auto_increment,
  `imm_id` int(10) NOT NULL,
  `i_id` int(10) unsigned NULL,
  `i_external_id` varchar(256) NULL,
  PRIMARY KEY  (`imd_id`),
  CONSTRAINT `fk_imd_imm_id` FOREIGN KEY (`imm_id`) REFERENCES `item_move_monitor` (`imm_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_imd_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `item_detail_status` (
  `ids_id` int(10) NOT NULL auto_increment,
  `imd_id` int(10) NOT NULL,
  `dst_id` int(10) NOT NULL,
  `imd_status_detail` varchar(5000) NULL,
  PRIMARY KEY  (`ids_id`),
  CONSTRAINT `fk_ids_imd_id` FOREIGN KEY (`imd_id`) REFERENCES `item_move_details` (`imd_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ids_dst_id` FOREIGN KEY (`dst_id`) REFERENCES `detail_status_type` (`dst_id`) ON DELETE CASCADE
) ENGINE=InnoDB;





