ALTER TABLE item_fragment ADD COLUMN if_set_seq tinyint(3) UNSIGNED NOT NULL AFTER if_type;
ALTER TABLE item_fragment ADD INDEX (if_set_seq);