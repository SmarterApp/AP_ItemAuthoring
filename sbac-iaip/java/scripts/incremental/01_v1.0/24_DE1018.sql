/* these tables serve as reference tables for passage audit log*/

DROP TABLE IF EXISTS `user_action_passage`;

CREATE TABLE `user_action_passage` (
  `uap_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `p_id` int(10) unsigned NOT NULL,
  `u_id` int(10) unsigned NOT NULL,
  `uap_timestamp` timestamp,
  `uap_process` varchar(255),
  `uap_detail` varchar(255),
  PRIMARY KEY (`uap_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `deleted_passage`;

CREATE TABLE `deleted_passage` (
  `p_id` int(10) unsigned NOT NULL,
  `ib_id` int(10) unsigned NOT NULL,
  `p_name` varchar(60) NOT NULL,
  `p_dev_state` tinyint unsigned NOT NULL,
  `p_publication_status` tinyint unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

