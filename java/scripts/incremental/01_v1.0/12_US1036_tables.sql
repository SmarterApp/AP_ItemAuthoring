/* this table serves as reference table for passage genres. Used in passage report*/

DROP TABLE IF EXISTS `genre`;

CREATE TABLE `genre` (
  `g_id` tinyint(3) unsigned NOT NULL,
  `g_name` varchar(20) NOT NULL,
  PRIMARY KEY (`g_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
