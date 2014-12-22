ALTER TABLE `user` ADD COLUMN `u_title` VARCHAR(4) NOT NULL DEFAULT ''  AFTER `u_review_type` , ADD COLUMN `u_first_name` VARCHAR(35) NOT NULL DEFAULT ''  AFTER `u_title` , ADD COLUMN `u_middle_name` VARCHAR(35) NOT NULL DEFAULT ''  AFTER `u_first_name` , ADD COLUMN `u_last_name` VARCHAR(35) NOT NULL DEFAULT ''  AFTER `u_middle_name` , ADD COLUMN `u_suffix` CHAR(3) NOT NULL DEFAULT ''  AFTER `u_last_name` , ADD COLUMN `u_phone` VARCHAR(15) NOT NULL DEFAULT ''  AFTER `u_suffix` , ADD COLUMN `u_email` VARCHAR(45) NOT NULL DEFAULT ''  AFTER `u_phone` , ADD COLUMN `u_writer_code` VARCHAR(20) NOT NULL DEFAULT ''  AFTER `u_email`;

ALTER TABLE `user` CHANGE COLUMN `u_password` `u_password` VARCHAR(64) NOT NULL DEFAULT '';

-- u_password is now Apache MD5 (NOTE: this is still insecure and mysql MD5 function is incompatable)
-- TODO :: Instead of hardcode hash: 'openssl passwd -apr1 u_password' or similar to get Apache MD5 hash
-- NOTE :: From mysql command line: 'system htpasswd -mnb username password' (CAVEAT: runs on client, and cannot capture output)
-- TODO :: Consider MySQL UDF (Perhaps call libgnutls-openssl.so or sys_exec [serious security considertions here])
UPDATE user SET u_password='$apr1$uU46CBSP$W1lq7k2klKyuR.yIXyFEq0' WHERE u_username='system'; 

CREATE TABLE `user_oob_auth` (
  `oob_id` int(11) unsigned NOT NULL auto_increment,
  `oob_valid` tinyint(1) default '0',
  `oob_expires` datetime NOT NULL,
  `oob_updated` datetime default NULL,
  `oob_type` varchar(45) NOT NULL default 'EMAIL',
  `oob_u_id` int(10) NOT NULL,
  `oob_key` varchar(256) NOT NULL,
  PRIMARY KEY  (`oob_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

update user dest 
    left join administrator src on dest.u_id=src.u_id 
    set 
        u_title=ad_title,
        u_first_name=ad_first_name,
        u_middle_name=ad_middle_name,
        u_last_name=ad_last_name,
        u_suffix=ad_suffix,
        u_phone=ad_phone,
        u_email=ad_email,
        u_writer_code=ad_writer_code;

DROP TABLE IF EXISTS `administrator`;
