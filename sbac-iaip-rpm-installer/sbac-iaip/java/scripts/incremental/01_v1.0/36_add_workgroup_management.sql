/* new tables and fields to support workgroup management */

DROP TABLE IF EXISTS `workgroup`;

CREATE TABLE `workgroup` ( 
  `w_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `w_name` varchar(50) NOT NULL,
  `ib_id` int(10) unsigned NOT NULL,
  `w_description` varchar(100) NOT NULL,  
  PRIMARY KEY (`w_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `workgroup` ADD INDEX (`ib_id`);
ALTER TABLE `workgroup` ADD CONSTRAINT workgroup_fk_ib_id FOREIGN KEY (ib_id) REFERENCES item_bank(ib_id);

DROP TABLE IF EXISTS `workgroup_filter`;

CREATE TABLE `workgroup_filter` (
  `wf_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `w_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`wf_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `workgroup_filter` ADD INDEX(`w_id`);
ALTER TABLE `workgroup_filter` ADD CONSTRAINT workgroup_filter_fk_w_id FOREIGN KEY (w_id) REFERENCES workgroup(w_id);

DROP TABLE IF EXISTS `workgroup_filter_part`;

CREATE TABLE `workgroup_filter_part` (
  `wfp_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `wf_id` int(10) unsigned NOT NULL,
  `wf_type` int(10) unsigned NOT NULL,
  `wf_value` int(10) unsigned NOT NULL,
  PRIMARY KEY (`wfp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `workgroup_filter_part` ADD INDEX (`wf_id`);
ALTER TABLE `workgroup_filter_part` ADD CONSTRAINT workgroup_filter_part_fk_wf_id FOREIGN KEY (wf_id) REFERENCES workgroup_filter(wf_id);
