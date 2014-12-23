INSERT INTO `cdesbac`.`detail_status_type` (`dst_id`, `dst_code`, `dst_type`, `dst_value`) VALUES ('5', '4', 'error', 'Item already exists.');
UPDATE `cdesbac`.`detail_status_type` SET `dst_value`='Item already exists for the program:' WHERE `dst_id`='5';
INSERT INTO `cdesbac`.`detail_status_type` (`dst_id`, `dst_code`, `dst_type`, `dst_value`) VALUES ('6', '5', 'error', 'Passage name must be unique');

