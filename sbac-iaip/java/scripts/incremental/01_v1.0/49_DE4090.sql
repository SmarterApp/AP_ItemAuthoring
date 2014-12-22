USE cdesbac;

ALTER TABLE `cdesbac`.`item_move_status` 
CHANGE COLUMN `ims_value` `ims_value` VARCHAR(255) NULL DEFAULT NULL ;



UPDATE cdesbac.item_move_status SET ims_value = 'In Progress' WHERE ims_value = 'In Progres';

SELECT * FROM cdesbac.item_move_status;