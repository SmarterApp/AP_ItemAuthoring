/* new tables and fields to support passage set management */

DROP TABLE IF EXISTS `passage_set`;

CREATE TABLE `passage_set` ( 
  `ps_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ps_name` varchar(50) NOT NULL,
  `ib_id` int(10) unsigned NOT NULL,
  `ps_description` varchar(100) NOT NULL,  
  PRIMARY KEY (`ps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `passage_set_list`;

CREATE TABLE `passage_set_list` (
  `psl_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ps_id` int(10) unsigned NOT NULL,
  `p_id` int(10) unsigned NOT NULL,
  `psl_sequence` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`psl_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


