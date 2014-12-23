ALTER TABLE `cdesbac`.`accessibility_feature` 
CHANGE COLUMN `af_info` `af_info` TEXT CHARACTER SET 'utf8' COLLATE 'utf8_general_ci' NULL DEFAULT NULL ;


CREATE TABLE `glossary_languages` (
  `l_code` char(10) NOT NULL,
  `l_name` varchar(30) NOT NULL,
  `l_desc` varchar(300) NOT NULL, 
  PRIMARY KEY (`l_code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;