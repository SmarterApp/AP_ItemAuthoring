/* new table to support program share */

DROP TABLE IF EXISTS `item_bank_share`;

CREATE TABLE `item_bank_share` ( 
  `ibs_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ib_id` int(10) unsigned NOT NULL,
  `ibs_ib_share_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`ibs_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE INDEX item_bank_share_ib_id ON  item_bank_share(ib_id);
CREATE INDEX item_bank_share_ibs_ib_share_id ON  item_bank_share(ibs_ib_share_id);
