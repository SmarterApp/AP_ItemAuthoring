 
ALTER TABLE `stat_import_identifier` 
CHANGE COLUMN `sii_identifier` `sii_identifier` VARCHAR(5000) NOT NULL ,
CHANGE COLUMN `sii_comment` `sii_comment` VARCHAR(2500) NULL DEFAULT NULL ;
