/* Generic table for item metadata lookup values */
DROP TABLE IF EXISTS `metadata_lookup`;

CREATE TABLE `metadata_lookup` (
  `ml_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ml_value` varchar(50) NOT NULL,
  `ml_code` int(10) DEFAULT NULL,
  PRIMARY KEY (`ml_id`),
  KEY `idx_value` (`ml_value`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

/* Table to map metadata from XML to fields in item/passage table or entries in characterization table */
DROP TABLE IF EXISTS `metadata_mapping`;

CREATE TABLE `metadata_mapping` (
  `mm_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mm_object_type` tinyint(4) DEFAULT NULL COMMENT 'item: 4; passage: 7',
  `mm_xpath` text,
  `mm_field_name` varchar(50) DEFAULT NULL,
  `mm_characteristic` int(10) DEFAULT NULL,
  `mm_lookup_table_name` varchar(50) DEFAULT NULL,
  `mm_lookup_by_field` varchar(50) DEFAULT NULL,
  `mm_lookup_prefix` varchar(50) DEFAULT NULL,
  `mm_lookup_value_field` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`mm_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

/* Adding field to store imported metadata XML */
ALTER TABLE `item`   
  ADD COLUMN `i_metadata_xml` TEXT NULL AFTER `i_is_old_version`;
