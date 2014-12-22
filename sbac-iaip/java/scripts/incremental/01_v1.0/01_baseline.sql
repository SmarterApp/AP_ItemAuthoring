CREATE TABLE `accessibility_element` (
  `ae_id` int(10) NOT NULL auto_increment,
  `i_id` int(10) default NULL,
  `p_id` int(10) default NULL,
  `ae_name` varchar(10) NOT NULL,
  `ae_content_type` int(10) default NULL,
  `ae_content_name` varchar(100) default NULL,
  `ae_content_link_type` int(10) NOT NULL,
  `ae_text_link_type` int(10) default NULL,
  `ae_text_link_word` int(10) default NULL,
  `ae_text_link_start_char` int(10) default NULL,
  `ae_text_link_stop_char` int(10) default NULL,
  PRIMARY KEY  (`ae_id`),
  KEY `idx_item` (`i_id`),
  KEY `idx_passage` (`p_id`)
) ENGINE=InnoDB;
CREATE TABLE `accessibility_feature` (
  `af_id` int(10) NOT NULL auto_increment,
  `ae_id` int(10) NOT NULL,
  `af_type` int(10) default NULL,
  `af_feature` int(10) default NULL,
  `af_info` varchar(200) default NULL,
  `lang_code` char(5) default NULL,
  PRIMARY KEY  (`af_id`),
  KEY `idx_ae` (`ae_id`),
  CONSTRAINT `fk_accessibility_element` FOREIGN KEY (`ae_id`) REFERENCES `accessibility_element` (`ae_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB;
CREATE TABLE `administrator` (
  `u_id` int(10) unsigned NOT NULL default '0',
  `ad_external_id` blob,
  `ad_title` varchar(4) NOT NULL default '',
  `ad_first_name` varchar(30) NOT NULL default '',
  `ad_middle_name` varchar(30) NOT NULL default '',
  `ad_last_name` varchar(30) NOT NULL default '',
  `ad_suffix` char(3) NOT NULL default '',
  `ad_phone` varchar(15) NOT NULL default '',
  `ad_email` varchar(45) NOT NULL default '',
  `ad_base_u_id` int(10) unsigned NOT NULL default '0',
  `ad_writer_code` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`u_id`),
  KEY `EXTERNAL_ID` (`ad_external_id`(16)),
  KEY `BASE_UID` (`ad_base_u_id`),
  KEY `FIRST_NAME` (`ad_first_name`),
  KEY `LAST_NAME` (`ad_last_name`)
) ENGINE=InnoDB;
CREATE TABLE `blooms_taxonomy` (
  `bt_id` int(10) NOT NULL,
  `bt_name` varchar(20) NOT NULL,
  PRIMARY KEY  (`bt_id`)
) ENGINE=InnoDB;
CREATE TABLE `content_area` (
  `ca_id` int(10) unsigned NOT NULL auto_increment,
  `ca_name` varchar(20) default NULL,
  PRIMARY KEY  (`ca_id`)
) ENGINE=InnoDB;
CREATE TABLE `content_asset_pair` (
  `cap_id` int(11) NOT NULL auto_increment,
  `cap_object_type` tinyint(4) default NULL,
  `cap_object_id` int(11) NOT NULL,
  `cap_asset_name` varchar(100) NOT NULL,
  `cap_pair_name` varchar(100) NOT NULL,
  PRIMARY KEY  (`cap_id`),
  KEY `idx_o_type` (`cap_object_type`),
  KEY `idx_o_id` (`cap_object_id`)
) ENGINE=InnoDB;
CREATE TABLE `deleted_item` (
  `i_id` int(11) NOT NULL,
  `ib_id` int(11) NOT NULL,
  `i_external_id` varchar(30) NOT NULL,
  `i_dev_state` tinyint(4) NOT NULL,
  `i_publication_status` tinyint(4) NOT NULL,
  KEY `i_id` (`i_id`),
  KEY `ib_id` (`ib_id`)
) ENGINE=InnoDB;
CREATE TABLE `dev_state` (
  `ds_id` int(10) NOT NULL,
  `ds_name` varchar(100) default NULL,
  PRIMARY KEY  (`ds_id`)
) ENGINE=InnoDB;
CREATE TABLE `difficulty` (
  `d_id` int(10) NOT NULL,
  `d_name` varchar(10) default NULL,
  PRIMARY KEY  (`d_id`)
) ENGINE=InnoDB;
CREATE TABLE `grade_level` (
  `gl_id` int(10) NOT NULL,
  `gl_name` char(2) NOT NULL,
  PRIMARY KEY  (`gl_id`)
) ENGINE=InnoDB;
CREATE TABLE `hierarchy_definition` (
  `hd_id` int(10) unsigned NOT NULL auto_increment,
  `hd_type` tinyint(3) unsigned NOT NULL default '0',
  `hd_value` text NOT NULL,
  `hd_parent_id` int(10) unsigned NOT NULL default '0',
  `hd_posn_in_parent` int(10) unsigned NOT NULL default '0',
  `hd_std_desc` text,
  `hd_extended_desc` text,
  `hd_parent_path` varchar(100) default NULL,
  PRIMARY KEY  (`hd_id`),
  KEY `PARENT` (`hd_parent_id`),
  KEY `TYPE` (`hd_type`),
  KEY `POSN` (`hd_posn_in_parent`)
) ENGINE=InnoDB;
CREATE TABLE `inclusion_order` (
  `io_id` int(10) NOT NULL auto_increment,
  `i_id` int(10) default NULL,
  `p_id` int(10) default NULL,
  `io_type` tinyint(4) default NULL,
  PRIMARY KEY  (`io_id`),
  KEY `idx_i_id` (`i_id`),
  KEY `idx_p_id` (`p_id`)
) ENGINE=InnoDB;
CREATE TABLE `inclusion_order_element` (
  `ioe_id` int(10) NOT NULL auto_increment,
  `io_id` int(10) NOT NULL,
  `ae_id` int(10) default NULL,
  `ioe_sequence` tinyint(4) default NULL,
  PRIMARY KEY  (`ioe_id`),
  KEY `idx_inclusion_order` (`io_id`),
  KEY `idx_accessibility_elelement` (`ae_id`),
  CONSTRAINT `fk_ioe_accessibility_element` FOREIGN KEY (`ae_id`) REFERENCES `accessibility_element` (`ae_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ioe_inclusion_order` FOREIGN KEY (`io_id`) REFERENCES `inclusion_order` (`io_id`) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE `item` (
  `i_id` int(10) unsigned NOT NULL auto_increment,
  `i_external_id` varchar(30) default NULL,
  `ib_id` int(10) unsigned default NULL,
  `i_type` tinyint(4) NOT NULL default '0',
  `i_description` varchar(100) default NULL,
  `i_difficulty` tinyint(4) NOT NULL default '0',
  `i_last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `i_last_edited_by` int(10) unsigned NOT NULL default '0',
  `i_dev_state` tinyint(4) unsigned NOT NULL default '0',
  `i_xml_data` text NOT NULL,
  `i_response_cnt` int(10) unsigned NOT NULL default '0',
  `i_notes` text,
  `i_review_lock` tinyint(4) unsigned NOT NULL default '0',
  `i_review_lifetime` timestamp NOT NULL default '0000-00-00 00:00:00',
  `i_import_type` tinyint(4) NOT NULL default '0',
  `i_lang` tinyint(4) NOT NULL default '1',
  `i_correct_response` text,
  `i_author` int(10) unsigned NOT NULL default '0',
  `i_royalties` varchar(80) default NULL,
  `i_owner` varchar(80) default NULL,
  `i_export_ok` tinyint(1) unsigned NOT NULL default '0',
  `i_source_document` varchar(160) default NULL,
  `i_created` timestamp NOT NULL default '0000-00-00 00:00:00',
  `ip_id` int(11) unsigned default NULL,
  `i_publication_status` tinyint(1) NOT NULL default '0',
  `i_read_only` tinyint(1) NOT NULL default '0',
  `i_ims_id` varchar(20) NOT NULL default '0',
  `i_benchmark` varchar(10) default NULL,
  `i_version` tinyint(3) unsigned NOT NULL default '0',
  `i_handle` varchar(20) NOT NULL default '',
  `i_form_name` varchar(30) NOT NULL default '',
  `i_form_session` tinyint(4) NOT NULL default '0',
  `i_form_sequence` tinyint(4) NOT NULL default '0',
  `i_last_save_user_id` int(10) unsigned NOT NULL,
  `i_cognitive_process` varchar(40) default NULL,
  `i_blooms_taxonomy` tinyint(4) NOT NULL default '0',
  `i_due_date` date default '0000-00-00',
  `i_readability_index` varchar(50) default NULL,
  `i_is_pi_set` tinyint(4) NOT NULL,
  `i_qti_xml_data` text NOT NULL,
  `i_tei_data` text NOT NULL,
  PRIMARY KEY  (`i_id`),
  KEY `EXTERNAL_ID` (`i_external_id`),
  KEY `TYPE` (`i_type`),
  KEY `ib_id` (`ib_id`),
  KEY `i_dev_state` (`i_dev_state`),
  KEY `i_review_lock` (`i_review_lock`),
  KEY `ip_id` (`ip_id`),
  KEY `i_read_only` (`i_read_only`),
  KEY `i_lang` (`i_lang`),
  KEY `i_version` (`i_version`)
) ENGINE=InnoDB;
CREATE TABLE `item_alternate` (
  `ia_id` int(10) unsigned NOT NULL auto_increment,
  `i_id` int(10) unsigned NOT NULL,
  `ia_alternate_i_id` int(10) unsigned NOT NULL,
  `ia_adaptation_type` tinyint(4) NOT NULL,
  `ia_representation_form` tinyint(4) NOT NULL,
  `ia_language` varchar(2) NOT NULL,
  `ia_alternate_label` varchar(50) NOT NULL,
  PRIMARY KEY  (`ia_id`),
  KEY `i_id` (`i_id`),
  KEY `ia_alternate_i_id` (`ia_alternate_i_id`)
) ENGINE=InnoDB;
CREATE TABLE `item_asset_attribute` (
  `iaa_id` int(11) NOT NULL auto_increment,
  `i_id` int(11) NOT NULL default '0',
  `iaa_filename` varchar(60) NOT NULL default '',
  `iaa_media_description` text,
  `iaa_source_url` varchar(200) NOT NULL default '',
  `iaa_u_id` int(11) NOT NULL default '0',
  `iaa_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `iaa_classification` varchar(5) default NULL,
  PRIMARY KEY  (`iaa_id`),
  KEY `i_id` (`i_id`),
  KEY `iaa_source_url` (`iaa_source_url`),
  KEY `iaa_u_id` (`iaa_u_id`)
) ENGINE=InnoDB;
CREATE TABLE `item_bank` (
  `ib_id` int(10) unsigned NOT NULL auto_increment,
  `o_id` int(10) unsigned NOT NULL,
  `tb_id` int(10) unsigned NOT NULL,
  `ib_external_id` varchar(20) NOT NULL default '',
  `ib_description` varchar(100) NOT NULL default '',
  `ib_owner` varchar(30) NOT NULL default '',
  `ib_version` date NOT NULL default '0000-00-00',
  `ib_host_base` varchar(50) NOT NULL default '',
  `ib_has_ims` tinyint(4) NOT NULL default '0',
  `ib_assign_ims_id` tinyint(4) NOT NULL default '0',
  `sh_id` int(10) unsigned NOT NULL default '0',
  `ib_importer_u_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`ib_id`),
  KEY `EXTERNAL_ID` (`ib_external_id`),
  KEY `tb_id` (`tb_id`)
) ENGINE=InnoDB;
CREATE TABLE `item_bank_metafiles` (
  `ibm_id` int(10) NOT NULL auto_increment,
  `ib_id` int(11) NOT NULL,
  `ibm_comment` text NOT NULL,
  `ibm_orig_name` varchar(255) NOT NULL,
  `ibm_system_name` varchar(255) NOT NULL,
  `ibm_type` varchar(50) NOT NULL,
  `ibm_version` tinyint(4) NOT NULL default '0',
  `ibm_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `ibm_original_id` int(10) default NULL,
  `ibm_type_code` tinyint(4) default NULL COMMENT '1 - item spec; 2 - passage spec; 3 - copyright; 4 - other',
  PRIMARY KEY  (`ibm_id`,`ibm_version`),
  KEY `ib_id` (`ib_id`)
) ENGINE=InnoDB;
CREATE TABLE `item_characterization` (
  `i_id` int(10) unsigned NOT NULL default '0',
  `ic_type` int(10) unsigned NOT NULL default '0',
  `ic_value` int(10) NOT NULL default '0',
  `ic_value_str` varchar(150) default NULL,
  KEY `ITEM_ID` (`i_id`),
  KEY `ID_TYPE` (`i_id`,`ic_type`),
  KEY `TYPE_VALUE` (`ic_type`,`ic_value`)
) ENGINE=InnoDB;
CREATE TABLE `item_comment` (
  `ic_id` int(10) unsigned NOT NULL auto_increment,
  `i_id` int(11) NOT NULL,
  `u_id` int(11) NOT NULL,
  `ic_type` int(11) NOT NULL,
  `ic_dev_state` int(11) NOT NULL,
  `ic_rating` tinyint(4) NOT NULL,
  `ic_comment` text NOT NULL,
  `ic_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ic_id`),
  KEY `i_id` (`i_id`),
  KEY `u_id` (`u_id`),
  KEY `ic_type` (`ic_type`)
) ENGINE=InnoDB;
CREATE TABLE `item_fragment` (
  `if_id` int(10) unsigned NOT NULL auto_increment,
  `i_id` int(10) unsigned NOT NULL,
  `if_type` tinyint(3) unsigned NOT NULL,
  `if_seq` tinyint(3) unsigned NOT NULL,
  `if_text` text NOT NULL,
  `if_audio_url` varchar(255) NOT NULL,
  PRIMARY KEY  (`if_id`),
  KEY `i_id` (`i_id`),
  KEY `if_type` (`if_type`),
  KEY `if_seq` (`if_seq`)
) ENGINE=InnoDB;
CREATE TABLE `item_import_action` (
  `ua_id` int(11) NOT NULL,
  `i_id` int(11) NOT NULL,
  `iia_type` tinyint(4) NOT NULL,
  KEY `ua_id` (`ua_id`),
  KEY `i_id` (`i_id`),
  KEY `iia_type` (`iia_type`)
) ENGINE=InnoDB;
CREATE TABLE `item_import_monitor` (
  `iim_id` int(11) NOT NULL auto_increment,
  `ib_id` int(10) unsigned NOT NULL,
  `u_id` int(11) NOT NULL,
  `ua_id` int(11) NOT NULL,
  `iim_status` tinyint(4) NOT NULL,
  `iim_status_detail` varchar(255) NOT NULL,
  `iim_dev_state` tinyint(4) NOT NULL,
  `iim_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `iim_import_file_name` varchar(255) NOT NULL,
  `iim_import_file_modified` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`iim_id`),
  KEY `ib_id` (`ib_id`),
  KEY `item_import_monitor_u_id` (`u_id`),
  KEY `item_import_monitor_ua_id` (`ua_id`)
) ENGINE=InnoDB;
CREATE TABLE `item_metafile_association` (
  `ima_id` int(10) NOT NULL auto_increment,
  `i_id` int(10) unsigned NOT NULL,
  `ibm_id` int(10) NOT NULL,
  `ibm_version` int(10) NOT NULL,
  PRIMARY KEY  (`ima_id`),
  UNIQUE KEY `idx_item_metafile` (`i_id`,`ibm_id`),
  KEY `idx_metafile` (`ibm_id`),
  CONSTRAINT `FK_ima_item` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
CREATE TABLE `item_metafiles` (
  `im_id` int(10) unsigned NOT NULL auto_increment,
  `i_id` int(10) unsigned NOT NULL default '0',
  `u_id` int(10) unsigned NOT NULL default '0',
  `i_dev_state` tinyint(4) NOT NULL default '0',
  `im_filename` varchar(255) NOT NULL default '',
  `im_timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  `im_comment` text NOT NULL,
  PRIMARY KEY  (`im_id`),
  KEY `i_id` (`i_id`)
) ENGINE=InnoDB;
CREATE TABLE `item_status` (
  `is_id` int(10) unsigned NOT NULL auto_increment,
  `i_id` int(10) unsigned NOT NULL default '0',
  `is_last_dev_state` tinyint(3) NOT NULL default '0',
  `is_new_dev_state` tinyint(3) unsigned NOT NULL default '1',
  `is_timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  `is_accepted_timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  `is_u_id` int(10) unsigned NOT NULL default '0',
  `i_xml_data` text NOT NULL,
  `i_notes` text,
  `i_qti_xml_data` text,
  `i_tei_data` text,
  PRIMARY KEY  (`is_id`),
  KEY `i_id` (`i_id`),
  KEY `is_last_dev_state` (`is_last_dev_state`),
  KEY `is_new_dev_state` (`is_new_dev_state`),
  KEY `is_u_id` (`is_u_id`),
  KEY `i_notes` (`i_notes`(5))
) ENGINE=InnoDB;
CREATE TABLE `item_type` (
  `it_id` int(10) NOT NULL,
  `it_name` varchar(30) NOT NULL,
  PRIMARY KEY  (`it_id`)
) ENGINE=InnoDB;
CREATE TABLE `languages` (
  `l_code` char(5) NOT NULL,
  `l_name` varchar(30) NOT NULL,
  PRIMARY KEY  (`l_code`)
) ENGINE=InnoDB;
CREATE TABLE `last_modification` (
  `lm_id` int(10) NOT NULL auto_increment,
  `lm_table_name` varchar(50) NOT NULL,
  `lm_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`lm_id`)
) ENGINE=InnoDB;
CREATE TABLE `object_characterization` (
  `oc_object_type` int(10) unsigned NOT NULL default '0',
  `oc_object_id` int(10) unsigned NOT NULL default '0',
  `oc_characteristic` int(10) unsigned NOT NULL default '0',
  `oc_int_value` int(11) NOT NULL default '0',
  KEY `OBJECT_TYPE_ID` (`oc_object_type`,`oc_object_id`),
  KEY `OBJECT_TYPE_ID_CHRSTC` (`oc_object_type`,`oc_object_id`,`oc_characteristic`),
  KEY `TYPE` (`oc_object_type`),
  KEY `EVERYTHING` (`oc_object_type`,`oc_object_id`,`oc_characteristic`,`oc_int_value`)
) ENGINE=InnoDB;
CREATE TABLE `organization` (
  `o_id` int(10) unsigned NOT NULL auto_increment,
  `o_name` varchar(40) NOT NULL,
  `o_description` varchar(255) NOT NULL,
  PRIMARY KEY  (`o_id`)
) ENGINE=InnoDB;
CREATE TABLE `passage` (
  `p_id` int(10) unsigned NOT NULL auto_increment,
  `p_name` varchar(60) NOT NULL default '',
  `ib_id` int(10) unsigned default NULL,
  `p_genre` tinyint(3) unsigned NOT NULL default '0',
  `p_subgenre` varchar(30) default NULL,
  `p_topic` varchar(40) default NULL,
  `p_reading_level` text,
  `p_summary` text,
  `p_word_count` int(10) unsigned NOT NULL default '0',
  `p_url` varchar(255) NOT NULL default '',
  `p_cross_curriculum` tinyint(3) unsigned NOT NULL default '0',
  `p_char_ethnicity` tinyint(3) unsigned NOT NULL default '0',
  `p_char_gender` tinyint(3) unsigned NOT NULL default '0',
  `p_notes` text,
  `p_button_name` varchar(30) default NULL,
  `p_code` varchar(4) NOT NULL default '',
  `p_lang` tinyint(1) unsigned NOT NULL default '1',
  `p_dev_state` tinyint(1) unsigned NOT NULL default '1',
  `p_author` int(10) unsigned NOT NULL default '0',
  `p_review_lock` tinyint(1) unsigned NOT NULL default '0',
  `p_review_lifetime` timestamp NOT NULL default '0000-00-00 00:00:00',
  `ip_id` int(10) unsigned NOT NULL default '0',
  `audio_script` longtext,
  `audio_file_url` varchar(254) default NULL,
  `audio_comments` longtext,
  `p_last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `p_audio_modified` timestamp NOT NULL default '0000-00-00 00:00:00',
  `p_is_pi_set` tinyint(4) NOT NULL,
  `p_readability_index` varchar(50) NOT NULL,
  `p_publication_status` tinyint(4) NOT NULL,
  PRIMARY KEY  (`p_id`),
  KEY `p_name` (`p_name`),
  KEY `ib_id` (`ib_id`),
  KEY `p_dev_state` (`p_dev_state`),
  KEY `p_review_lock` (`p_review_lock`),
  KEY `p_lang` (`p_lang`),
  KEY `p_code` (`p_code`)
) ENGINE=InnoDB;
CREATE TABLE `passage_comment` (
  `pc_id` int(10) unsigned NOT NULL auto_increment,
  `p_id` int(11) NOT NULL,
  `u_id` int(11) NOT NULL,
  `pc_type` int(11) NOT NULL,
  `pc_dev_state` int(11) NOT NULL,
  `pc_rating` tinyint(4) NOT NULL,
  `pc_comment` text NOT NULL,
  `pc_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`pc_id`),
  KEY `idx_p_id` (`p_id`),
  KEY `idx_u_id` (`u_id`),
  KEY `idx_pc_type` (`pc_type`)
) ENGINE=InnoDB;
CREATE TABLE `passage_item_set` (
  `pis_id` int(10) unsigned NOT NULL auto_increment,
  `p_id` int(10) unsigned NOT NULL default '0',
  `i_id` int(10) unsigned NOT NULL default '0',
  `pis_sequence` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`pis_id`),
  KEY `p_id` (`p_id`),
  KEY `i_id` (`i_id`)
) ENGINE=InnoDB;
CREATE TABLE `passage_media` (
  `pm_id` int(10) NOT NULL auto_increment,
  `p_id` int(10) NOT NULL default '0',
  `pm_clnt_filename` varchar(60) NOT NULL default '',
  `pm_srvr_filename` varchar(60) NOT NULL default '',
  `pm_description` text,
  `pm_u_id` int(10) NOT NULL default '0',
  `pm_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`pm_id`),
  KEY `idx_i_id` (`p_id`),
  KEY `idx_pm_clnt_filename` (`pm_clnt_filename`),
  KEY `idx_pm_u_id` (`pm_u_id`)
) ENGINE=InnoDB;
CREATE TABLE `passage_metafile_association` (
  `pma_id` int(10) NOT NULL auto_increment,
  `p_id` int(10) unsigned NOT NULL,
  `ibm_id` int(10) NOT NULL,
  `ibm_version` int(10) NOT NULL,
  PRIMARY KEY  (`pma_id`),
  UNIQUE KEY `idx_passage_metafile` (`p_id`,`ibm_id`),
  KEY `idx_metafile` (`ibm_id`),
  CONSTRAINT `FK_pma_passage` FOREIGN KEY (`p_id`) REFERENCES `passage` (`p_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
CREATE TABLE `passage_metafiles` (
  `pm_id` int(11) NOT NULL auto_increment,
  `p_id` int(11) NOT NULL default '0',
  `u_id` int(11) NOT NULL default '0',
  `p_dev_state` tinyint(4) NOT NULL default '0',
  `pm_filename` varchar(255) NOT NULL default '',
  `pm_timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  `pm_comment` text NOT NULL,
  PRIMARY KEY  (`pm_id`)
) ENGINE=InnoDB;
CREATE TABLE `passage_status` (
  `ps_id` int(10) unsigned NOT NULL auto_increment,
  `p_id` int(10) unsigned NOT NULL default '0',
  `ps_last_dev_state` tinyint(3) NOT NULL default '0',
  `ps_new_dev_state` tinyint(3) unsigned NOT NULL default '1',
  `ps_timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  `ps_accepted_timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  `ps_u_id` int(10) unsigned NOT NULL default '0',
  `p_content` text NOT NULL,
  `p_notes` text NOT NULL,
  `ps_footnotes` text NOT NULL,
  PRIMARY KEY  (`ps_id`),
  KEY `p_id` (`p_id`),
  KEY `ps_last_dev_state` (`ps_last_dev_state`),
  KEY `ps_new_dev_state` (`ps_new_dev_state`),
  KEY `ps_u_id` (`ps_u_id`)
) ENGINE=InnoDB;
CREATE TABLE `publication_status` (
  `ps_id` int(10) NOT NULL,
  `ps_name` varchar(10) NOT NULL,
  PRIMARY KEY  (`ps_id`)
) ENGINE=InnoDB;
CREATE TABLE `qualifier_label` (
  `sh_id` int(10) unsigned NOT NULL default '0',
  `ql_type` int(10) unsigned NOT NULL default '0',
  `ql_label` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`sh_id`,`ql_type`)
) ENGINE=InnoDB;
CREATE TABLE `scoring_rubric` (
  `sr_id` int(10) unsigned NOT NULL auto_increment,
  `ib_id` int(10) unsigned NOT NULL default '0',
  `sr_name` varchar(40) NOT NULL default '',
  `sr_description` text NOT NULL,
  `sr_url` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`sr_id`)
) ENGINE=InnoDB;
CREATE TABLE `session` (
  `ss_id` varchar(32) NOT NULL default '',
  `u_id` int(10) unsigned default '0',
  `ss_variables` longtext,
  `ss_start_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `ss_expiration` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`ss_id`)
) ENGINE=InnoDB;
CREATE TABLE `standard_hierarchy` (
  `sh_id` int(10) unsigned NOT NULL auto_increment,
  `sh_external_id` varchar(20) default NULL,
  `sh_name` varchar(50) NOT NULL default '',
  `sh_description` varchar(255) NOT NULL default '',
  `sh_released` date NOT NULL default '0000-00-00',
  `sh_source` varchar(50) NOT NULL default '',
  `hd_id` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`sh_id`),
  KEY `EXTERNAL_ID` (`sh_external_id`)
) ENGINE=InnoDB;
CREATE TABLE `stat_administration_status` (
  `sas_id` int(10) NOT NULL,
  `sas_name` varchar(50) NOT NULL,
  PRIMARY KEY (`sas_id`)
) ENGINE=InnoDB;
CREATE TABLE `stat_administration` (
  `sa_id` int(10) NOT NULL AUTO_INCREMENT,
  `sa_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `sa_identifier` varchar(30) NOT NULL,
  `sa_comment` varchar(250) DEFAULT NULL,
  `ib_id` int(10) NOT NULL,
  `sa_admin_date` date DEFAULT NULL,
  `sas_id` int(10) DEFAULT NULL,
  PRIMARY KEY (`sa_id`),
  KEY `FK_sas` (`sas_id`),
  CONSTRAINT `FK_sas` FOREIGN KEY (`sas_id`) REFERENCES `stat_administration_status` (`sas_id`)
) ENGINE=InnoDB;
CREATE TABLE `stat_key` (
  `sk_id` int(10) NOT NULL AUTO_INCREMENT,
  `sk_name` varchar(20) NOT NULL,
  `sk_description` varchar(100) DEFAULT NULL,
  `sk_type` varchar(20) NOT NULL,
  `sk_domain` int(2) DEFAULT NULL COMMENT '1 = item statistic, 2 = administration statistic, 3 = both',
  PRIMARY KEY (`sk_id`),
  KEY `idx_sk_name` (`sk_name`)
) ENGINE=InnoDB;
CREATE TABLE `stat_administration_value` (
  `sav_id` int(10) NOT NULL AUTO_INCREMENT,
  `sa_id` int(10) NOT NULL,
  `sk_id` int(10) NOT NULL,
  `sav_numeric_value` float DEFAULT NULL,
  `sav_char_value` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`sav_id`),
  KEY `idx_sa_id` (`sa_id`),
  KEY `idx_sk_id` (`sk_id`),
  CONSTRAINT `FK_sav_sa` FOREIGN KEY (`sa_id`) REFERENCES `stat_administration` (`sa_id`),
  CONSTRAINT `FK_sav_sk` FOREIGN KEY (`sk_id`) REFERENCES `stat_key` (`sk_id`)
) ENGINE=InnoDB;
CREATE TABLE `stat_item_value` (
  `siv_id` int(10) NOT NULL AUTO_INCREMENT,
  `sa_id` int(10) NOT NULL,
  `i_id` int(10) unsigned NOT NULL,
  `sk_id` int(10) NOT NULL,
  `siv_numeric_value` float DEFAULT NULL,
  PRIMARY KEY (`siv_id`),
  KEY `idx_sa_id` (`sa_id`),
  KEY `idx_i_id` (`i_id`),
  KEY `idx_sk_id` (`sk_id`),
  KEY `idx_sa_item_sk` (`sa_id`,`i_id`,`sk_id`),
  CONSTRAINT `FK_siv_item` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_siv_sa` FOREIGN KEY (`sa_id`) REFERENCES `stat_administration` (`sa_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `FK_siv_sk` FOREIGN KEY (`sk_id`) REFERENCES `stat_key` (`sk_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB;
CREATE TABLE `stat_key_value` (
  `skv_id` int(10) NOT NULL AUTO_INCREMENT,
  `sk_id` int(10) NOT NULL,
  `skv_value` varchar(50) NOT NULL,
  PRIMARY KEY (`skv_id`),
  KEY `idx_sk_id` (`sk_id`),
  CONSTRAINT `PK_skv_sk` FOREIGN KEY (`sk_id`) REFERENCES `stat_key` (`sk_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB;
CREATE TABLE `user` (
  `u_id` int(10) unsigned NOT NULL auto_increment,
  `u_external_id` int(10) unsigned default NULL,
  `u_username` varchar(30) NOT NULL default '',
  `u_password` varchar(30) NOT NULL default '',
  `u_type` tinyint(3) unsigned NOT NULL default '0',
  `u_active` tinyint(3) unsigned NOT NULL default '1',
  `u_last_update` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `u_deleted` tinyint(3) unsigned NOT NULL default '0',
  `u_del_date_time` datetime default NULL,
  `u_permissions` int(10) unsigned NOT NULL default '0',
  `o_id` int(10) unsigned NOT NULL,
  `u_admin_type` tinyint(3) unsigned NOT NULL,
  `u_review_type` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`u_id`),
  UNIQUE KEY `USERNAME` (`u_username`),
  UNIQUE KEY `USERNAME_PASSWORD` (`u_username`,`u_password`),
  KEY `EXTERNAL_ID` (`u_external_id`),
  KEY `TYPE` (`u_type`),
  KEY `DELETED` (`u_deleted`),
  KEY `ACTIVE` (`u_active`),
  KEY `o_id` (`o_id`),
  KEY `u_review_type` (`u_review_type`)
) ENGINE=InnoDB;
CREATE TABLE `user_action` (
  `ua_id` int(11) NOT NULL auto_increment,
  `ua_type` int(11) NOT NULL,
  `u_id` int(11) NOT NULL,
  `ua_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`ua_id`),
  KEY `user_action_ua_type` (`ua_type`),
  KEY `user_action_u_id` (`u_id`)
) ENGINE=InnoDB;
CREATE TABLE `user_action_item` (
  `uai_id` int(10) unsigned NOT NULL auto_increment,
  `i_id` int(11) NOT NULL,
  `u_id` int(11) NOT NULL,
  `uai_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `uai_process` varchar(255) NOT NULL,
  `uai_detail` varchar(255) NOT NULL,
  PRIMARY KEY  (`uai_id`)
) ENGINE=InnoDB;
CREATE TABLE `user_permission` (
  `u_id` int(11) NOT NULL default '0',
  `up_type` int(11) NOT NULL default '0',
  `up_value` int(11) NOT NULL default '0',
  KEY `u_id` (`u_id`),
  KEY `up_type` (`up_type`)
) ENGINE=InnoDB;
CREATE TABLE `work_supplemental_info` (
  `wsi_id` int(11) NOT NULL auto_increment,
  `ib_id` int(11) NOT NULL,
  `wsi_object_type` tinyint(4) NOT NULL,
  `wsi_object_id` int(11) NOT NULL,
  `wsi_work_type` tinyint(4) NOT NULL,
  `wsi_u_id` int(11) default NULL,
  PRIMARY KEY  (`wsi_id`),
  KEY `ib_id` (`ib_id`),
  KEY `wsi_object_type` (`wsi_object_type`),
  KEY `wsi_object_id` (`wsi_object_id`),
  KEY `wsi_work_type` (`wsi_work_type`),
  KEY `wsi_u_id` (`wsi_u_id`)
) ENGINE=InnoDB;
CREATE TABLE `work_supplemental_info_part` (
  `wsip_id` int(11) NOT NULL auto_increment,
  `wsi_id` int(11) NOT NULL,
  PRIMARY KEY  (`wsip_id`),
  KEY `wsi_id` (`wsi_id`)
) ENGINE=InnoDB;

/* required to run application */
CREATE TABLE `item_project` (
  `ip_id` int(11) unsigned NOT NULL auto_increment,
  `ib_id` int(11) unsigned NOT NULL default '0',
  `ip_name` varchar(50) NOT NULL default '',
  `ip_description` varchar(160) default NULL,
  PRIMARY KEY  (`ip_id`)
) ENGINE=InnoDB;
CREATE TABLE `test_bank` (
  `tb_id` int(10) unsigned NOT NULL auto_increment,
  `tb_name` varchar(50) NOT NULL,
  `tb_description` varchar(255) NOT NULL,
  PRIMARY KEY  (`tb_id`)
) ENGINE=InnoDB;
CREATE TABLE `test_group` (
  `tg_id` int(10) unsigned NOT NULL auto_increment,
  `tb_id` int(10) unsigned NOT NULL,
  `tg_name` varchar(40) NOT NULL,
  `tg_description` varchar(255) NOT NULL,
  PRIMARY KEY  (`tg_id`)
) ENGINE=InnoDB;

