ALTER TABLE `cdesbac`.`stat_key`
CHANGE COLUMN `sk_name` `sk_name` varchar(255) NOT NULL;

ALTER TABLE `cdesbac`.`stat_key`
CHANGE COLUMN `sk_description` `sk_description` varchar(4000) DEFAULT NULL;

ALTER TABLE `cdesbac`.`stat_item_value`
CHANGE COLUMN `siv_numeric_value` `siv_numeric_value` varchar(4000) DEFAULT NULL;