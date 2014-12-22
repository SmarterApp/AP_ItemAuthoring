DROP TABLE IF EXISTS `item_format`;

CREATE TABLE `item_format` (
  `itf_id` int(10) unsigned NOT NULL,
  `itf_name` varchar(50) NOT NULL,
  PRIMARY KEY (`itf_id`),
  KEY `idx_name` (`itf_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO item_format SET itf_id=1, itf_name='Selected Response';
INSERT INTO item_format SET itf_id=2, itf_name='Constructed Response';
INSERT INTO item_format SET itf_id=3, itf_name='Activity Based';
INSERT INTO item_format SET itf_id=4, itf_name='Performance Task';
