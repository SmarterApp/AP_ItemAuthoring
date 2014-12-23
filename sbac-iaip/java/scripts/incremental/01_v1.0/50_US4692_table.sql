ALTER TABLE `cdesbac`.`item_move_details` 
ADD COLUMN `imd_external_id` VARCHAR(256) NULL;

ALTER TABLE `cdesbac`.`item_move_monitor` 
ADD COLUMN `error_status` VARCHAR(45) NULL;

ALTER TABLE `cdesbac`.`passage` 
CHANGE COLUMN `p_is_pi_set` `p_is_pi_set` TINYINT(4) NOT NULL DEFAULT 0 ;

ALTER TABLE `cdesbac`.`passage` 
CHANGE COLUMN `p_readability_index` `p_readability_index` VARCHAR(50) NOT NULL DEFAULT '-' ;

ALTER TABLE `cdesbac`.`passage` 
CHANGE COLUMN `p_publication_status` `p_publication_status` TINYINT(4) NOT NULL DEFAULT 0 ;

/* Added on (9/7/2014) */
CREATE TABLE `cdesbac`.`content_resources` (
  `cr_id` INT NOT NULL AUTO_INCREMENT,
  `cr_type` VARCHAR(30) NOT NULL,
  `cr_external_id` VARCHAR(256) NOT NULL,
  `cr_source_url` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`cr_id`));

ALTER TABLE `cdesbac`.`external_content_metadata` 
ADD COLUMN `cr_id` INT(10) NULL AFTER `ecm_content_data`;

ALTER TABLE `cdesbac`.`content_attachment` 
ADD COLUMN `cr_id` INT(10) NULL AFTER `ca_source_url`;

INSERT INTO `cdesbac`.`detail_status_type` (`dst_id`, `dst_code`, `dst_type`, `dst_value`) VALUES ('3', '2', 'error', 'Missing resource');
INSERT INTO `cdesbac`.`detail_status_type` (`dst_id`, `dst_code`, `dst_type`, `dst_value`) VALUES ('4', '3', 'error', 'Invalid xml format');





 
