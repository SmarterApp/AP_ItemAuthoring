/* Populating test entries into metadata_mapping table; most likely will be deleted later */
insert  into `metadata_mapping`(`mm_id`,`mm_object_type`,`mm_xpath`,`mm_field_name`,`mm_characteristic`,`mm_lookup_table_name`,`mm_lookup_by_field`,`mm_lookup_prefix`,`mm_lookup_value_field`) values (1,4,'/general/descriptions/strings/@value','i_description',NULL,NULL,NULL,NULL,NULL);
insert  into `metadata_mapping`(`mm_id`,`mm_object_type`,`mm_xpath`,`mm_field_name`,`mm_characteristic`,`mm_lookup_table_name`,`mm_lookup_by_field`,`mm_lookup_prefix`,`mm_lookup_value_field`) values (2,4,'/educational/difficulty/@value','i_difficulty',NULL,'difficulty','d_name',NULL,'d_id');
insert  into `metadata_mapping`(`mm_id`,`mm_object_type`,`mm_xpath`,`mm_field_name`,`mm_characteristic`,`mm_lookup_table_name`,`mm_lookup_by_field`,`mm_lookup_prefix`,`mm_lookup_value_field`) values (3,4,'/educational/interactivityType/@value',NULL,101,'metadata_lookup','ml_value','Interactivity:','ml_code');