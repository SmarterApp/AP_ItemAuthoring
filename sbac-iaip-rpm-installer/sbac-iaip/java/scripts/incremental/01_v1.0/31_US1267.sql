/* new tables and fields to support item interaction definitions */

DROP TABLE IF EXISTS `item_interaction`;

CREATE TABLE `item_interaction` ( 
  `ii_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ii_name` varchar(50) NOT NULL,
  `i_id` int(10) unsigned NOT NULL,
  `ii_type` tinyint(4) NOT NULL,
  `ii_max_score` float NOT NULL,
  `ii_score_type` tinyint(4) NOT NULL,
  `ii_correct` varchar(100) NULL,
  `ii_correct_map` text NULL,
  `ii_attribute_list` text NULL,
  PRIMARY KEY (`ii_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `item_status_fragment`;

CREATE TABLE `item_status_fragment` (
  `isf_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `is_id` int(10) unsigned NOT NULL,
  `i_id` int(10) unsigned NOT NULL,
  `if_id` int(10) unsigned NOT NULL,
  `isf_text` text NULL,
  PRIMARY KEY (`isf_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `item_fragment` ADD COLUMN `ii_id` int(11) unsigned NOT NULL AFTER `i_id`;
ALTER TABLE `item_fragment` ADD COLUMN `if_identifier` varchar(100) NULL AFTER `if_seq`;
ALTER TABLE `item_fragment` ADD COLUMN `if_attribute_list` text NULL AFTER `if_text`;

ALTER TABLE `item` ADD COLUMN `i_format` tinyint(4) NOT NULL AFTER `i_type`;

