DROP TABLE IF EXISTS `bloom_taxonomy`;

DROP TABLE IF EXISTS `blooms_taxonomy`;

CREATE TABLE `blooms_taxonomy` (
  `bt_id` int(10) NOT NULL,
  `bt_name` varchar(30) NOT NULL,
  PRIMARY KEY (`bt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `difficulty`;

CREATE TABLE `difficulty` (
  `d_id` int(10) NOT NULL,
  `d_name` varchar(20) NOT NULL,
  PRIMARY KEY (`d_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

