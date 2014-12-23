-- MySQL dump 10.13  Distrib 5.1.73, for redhat-linux-gnu (i686)
--
-- Host: localhost    Database: cdesbac
-- ------------------------------------------------------
-- Server version	5.1.73

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `accessibility_element`
--

DROP TABLE IF EXISTS `accessibility_element`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accessibility_element` (
  `ae_id` int(10) NOT NULL AUTO_INCREMENT,
  `i_id` int(10) DEFAULT NULL,
  `p_id` int(10) DEFAULT NULL,
  `ae_name` varchar(100) NOT NULL,
  `ae_content_type` int(10) DEFAULT NULL,
  `ae_content_name` varchar(100) DEFAULT NULL,
  `ae_content_link_type` int(10) NOT NULL,
  `ae_text_link_type` int(10) DEFAULT NULL,
  `ae_text_link_word` int(10) DEFAULT NULL,
  `ae_text_link_start_char` int(10) DEFAULT NULL,
  `ae_text_link_stop_char` int(10) DEFAULT NULL,
  PRIMARY KEY (`ae_id`),
  KEY `idx_item` (`i_id`),
  KEY `idx_passage` (`p_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accessibility_element`
--

LOCK TABLES `accessibility_element` WRITE;
/*!40000 ALTER TABLE `accessibility_element` DISABLE KEYS */;
/*!40000 ALTER TABLE `accessibility_element` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `accessibility_feature`
--

DROP TABLE IF EXISTS `accessibility_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accessibility_feature` (
  `af_id` int(10) NOT NULL AUTO_INCREMENT,
  `ae_id` int(10) NOT NULL,
  `af_type` int(10) DEFAULT NULL,
  `af_feature` int(10) DEFAULT NULL,
  `af_info` text,
  `lang_code` char(5) DEFAULT NULL,
  PRIMARY KEY (`af_id`),
  KEY `idx_ae` (`ae_id`),
  CONSTRAINT `fk_accessibility_element` FOREIGN KEY (`ae_id`) REFERENCES `accessibility_element` (`ae_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accessibility_feature`
--

LOCK TABLES `accessibility_feature` WRITE;
/*!40000 ALTER TABLE `accessibility_feature` DISABLE KEYS */;
/*!40000 ALTER TABLE `accessibility_feature` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `characterization_for_item_view`
--

DROP TABLE IF EXISTS `characterization_for_item_view`;
/*!50001 DROP VIEW IF EXISTS `characterization_for_item_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `characterization_for_item_view` (
 `i_id` tinyint NOT NULL,
  `item_standard` tinyint NOT NULL,
  `content_area` tinyint NOT NULL,
  `grade_level` tinyint NOT NULL,
  `grade_span_start` tinyint NOT NULL,
  `grade_span_end` tinyint NOT NULL,
  `points` tinyint NOT NULL,
  `depth_of_knowledge` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `characterization_for_passage_view`
--

DROP TABLE IF EXISTS `characterization_for_passage_view`;
/*!50001 DROP VIEW IF EXISTS `characterization_for_passage_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `characterization_for_passage_view` (
 `p_id` tinyint NOT NULL,
  `content_area` tinyint NOT NULL,
  `grade_level` tinyint NOT NULL,
  `grade_span_start` tinyint NOT NULL,
  `grade_span_end` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `content_area`
--

DROP TABLE IF EXISTS `content_area`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `content_area` (
  `ca_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ca_name` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`ca_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `content_area`
--

LOCK TABLES `content_area` WRITE;
/*!40000 ALTER TABLE `content_area` DISABLE KEYS */;
INSERT INTO `content_area` VALUES (1,'Math'),(2,'ELA');
/*!40000 ALTER TABLE `content_area` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `content_asset_pair`
--

DROP TABLE IF EXISTS `content_asset_pair`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `content_asset_pair` (
  `cap_id` int(11) NOT NULL AUTO_INCREMENT,
  `cap_object_type` tinyint(4) DEFAULT NULL,
  `cap_object_id` int(11) NOT NULL,
  `cap_asset_name` varchar(100) NOT NULL,
  `cap_pair_name` varchar(100) NOT NULL,
  PRIMARY KEY (`cap_id`),
  KEY `idx_o_type` (`cap_object_type`),
  KEY `idx_o_id` (`cap_object_id`),
  KEY `cap_asset_name` (`cap_asset_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `content_asset_pair`
--

LOCK TABLES `content_asset_pair` WRITE;
/*!40000 ALTER TABLE `content_asset_pair` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_asset_pair` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deleted_item`
--

DROP TABLE IF EXISTS `deleted_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deleted_item` (
  `i_id` int(11) NOT NULL,
  `ib_id` int(11) NOT NULL,
  `i_external_id` varchar(30) NOT NULL,
  `i_dev_state` tinyint(4) NOT NULL,
  `i_publication_status` tinyint(4) NOT NULL,
  KEY `i_id` (`i_id`),
  KEY `ib_id` (`ib_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deleted_item`
--

LOCK TABLES `deleted_item` WRITE;
/*!40000 ALTER TABLE `deleted_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `deleted_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deleted_passage`
--

DROP TABLE IF EXISTS `deleted_passage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deleted_passage` (
  `p_id` int(10) unsigned NOT NULL,
  `ib_id` int(10) unsigned NOT NULL,
  `p_name` varchar(60) NOT NULL,
  `p_dev_state` tinyint(3) unsigned NOT NULL,
  `p_publication_status` tinyint(3) unsigned NOT NULL,
  KEY `p_id` (`p_id`),
  KEY `ib_id` (`ib_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deleted_passage`
--

LOCK TABLES `deleted_passage` WRITE;
/*!40000 ALTER TABLE `deleted_passage` DISABLE KEYS */;
/*!40000 ALTER TABLE `deleted_passage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dev_state`
--

DROP TABLE IF EXISTS `dev_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dev_state` (
  `ds_id` int(10) NOT NULL,
  `ds_name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`ds_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dev_state`
--

LOCK TABLES `dev_state` WRITE;
/*!40000 ALTER TABLE `dev_state` DISABLE KEYS */;
INSERT INTO `dev_state` VALUES (1,'Development'),(2,'Review'),(3,'Testing'),(4,'Approved'),(5,'Released'),(6,'Suspended'),(9,'Rejected'),(11,'Retired'),(12,'Content Review'),(13,'Content Review 2'),(14,'On Hold'),(15,'Scheduled'),(16,'Query Resolution'),(17,'Copy Review'),(18,'Copy/Proof Approval'),(19,'New Art'),(20,'Fix Art'),(21,'Client Approval'),(22,'Client Approval 2'),(23,'Client Approval 3'),(24,'Copy Teacher Review'),(25,'Copy F2F Review'),(26,'Copy Final Review'),(27,'2nd Copy Review'),(28,'Supervisor Review'),(29,'Client Preview'),(30,'Customer Proof'),(40,'Content Review 1'),(41,'Item Update 1'),(42,'Committee Review'),(43,'Item Update 2'),(44,'Content Review 3'),(45,'Sensitivity Review'),(46,'External Editor Review'),(47,'Content Review 4'),(48,'Item Update 3'),(49,'Content Review 5'),(50,'Art Request Review'),(51,'Pending Art'),(52,'Ready for Art'),(53,'Proofreading'),(54,'Content Review 6'),(55,'Item Update 4'),(56,'Content Review 7'),(57,'QA Review'),(58,'Program Director Review'),(60,'Banked'),(61,'Consortium Review'),(62,'DNU Item Pool'),(63,'Fix Media'),(64,'New Media'),(65,'Query Resolution'),(66,'Data Review'),(67,'Operational Item Pool'),(68,'Post Admin Review'),(69,'QC Presentation Review'),(70,'Post Committee'),(71,'Create Accessibility'),(72,'Edit Accessibility');
/*!40000 ALTER TABLE `dev_state` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `difficulty`
--

DROP TABLE IF EXISTS `difficulty`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `difficulty` (
  `d_id` int(10) NOT NULL,
  `d_name` varchar(20) NOT NULL,
  PRIMARY KEY (`d_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `difficulty`
--

LOCK TABLES `difficulty` WRITE;
/*!40000 ALTER TABLE `difficulty` DISABLE KEYS */;
INSERT INTO `difficulty` VALUES (1,'Easy'),(2,'Medium'),(3,'Hard');
/*!40000 ALTER TABLE `difficulty` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `genre`
--

DROP TABLE IF EXISTS `genre`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `genre` (
  `g_id` tinyint(3) unsigned NOT NULL,
  `g_name` varchar(20) NOT NULL,
  PRIMARY KEY (`g_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `genre`
--

LOCK TABLES `genre` WRITE;
/*!40000 ALTER TABLE `genre` DISABLE KEYS */;
INSERT INTO `genre` VALUES (0,''),(1,'Poem'),(2,'Fiction'),(3,'Proofreading'),(4,'Non-Fiction'),(5,'Biography/Interview'),(6,'Information Resource'),(7,'Drama');
/*!40000 ALTER TABLE `genre` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `grade_level`
--

DROP TABLE IF EXISTS `grade_level`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `grade_level` (
  `gl_id` int(10) NOT NULL,
  `gl_name` char(2) NOT NULL,
  PRIMARY KEY (`gl_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `grade_level`
--

LOCK TABLES `grade_level` WRITE;
/*!40000 ALTER TABLE `grade_level` DISABLE KEYS */;
INSERT INTO `grade_level` VALUES (-1,'?'),(0,'K'),(1,'1'),(2,'2'),(3,'3'),(4,'4'),(5,'5'),(6,'6'),(7,'7'),(8,'8'),(9,'9'),(10,'10'),(11,'11'),(12,'12');
/*!40000 ALTER TABLE `grade_level` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hierarchy_definition`
--

DROP TABLE IF EXISTS `hierarchy_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hierarchy_definition` (
  `hd_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hd_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hd_value` text NOT NULL,
  `hd_parent_id` int(10) unsigned NOT NULL DEFAULT '0',
  `hd_posn_in_parent` int(10) unsigned NOT NULL DEFAULT '0',
  `hd_std_desc` text,
  `hd_extended_desc` text,
  `hd_parent_path` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`hd_id`),
  KEY `PARENT` (`hd_parent_id`),
  KEY `TYPE` (`hd_type`),
  KEY `POSN` (`hd_posn_in_parent`),
  KEY `hd_parent_path` (`hd_parent_path`)
) ENGINE=InnoDB AUTO_INCREMENT=4925 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hierarchy_definition`
--

LOCK TABLES `hierarchy_definition` WRITE;
/*!40000 ALTER TABLE `hierarchy_definition` DISABLE KEYS */;
INSERT INTO `hierarchy_definition` VALUES (4874,1,'Teks',0,0,NULL,NULL,'0'),(4875,2,'Math',4874,1,'Math 101','Math 101','4874'),(4876,1,'CCS',0,0,NULL,NULL,'0'),(4877,2,'ELA',4876,1,'English Language Arts','ELA','4876'),(4878,2,'Math',4876,2,'Math','','4876'),(4879,3,'Grade 4',4877,1,'Grade 4','Grade 4','4877,4876'),(4880,3,'Grade 5',4877,2,'Grade 5','Grade 5','4877,4876'),(4881,4,'Reading-Literature',4879,1,'Reading-Literature','Reading-Literature','4879,4877,4876'),(4882,4,'Reading-Informational',4879,2,'Reading-Informational','Reading-Informational','4879,4877,4876'),(4883,5,'ELA4&amp;RL.1',4881,1,'Key Ideas and Details: Refer to details and examples in a text when explaining what the text says explicitly and when drawing inferences from the text.','ELA4.RL.1','4881,4879,4877,4876'),(4884,6,'ELA4.RL.1a',4883,1,'1. Refer to details and examples in a text when explaining what the text says explicitly and when drawing inferences from the text.','ELA4.RL.1a','4883,4881,4879,4877,4876'),(4886,2,'New Test Subject',4885,1,'Default Test Subject','','4885'),(4887,1,'Level1',0,0,NULL,NULL,'0'),(4888,5,'<html> hello world </html>',4887,1,'Content','<b>Big bold content</b>','4887'),(4889,1,'Bloom Hierarchy',0,0,NULL,NULL,'0'),(4890,2,'Bloom Test Subject',4889,1,'','','4889'),(4891,3,'Bloom Area',4890,1,'New node','New node','4890,4889'),(4892,4,'General Content',4891,1,'New node','New node','4891,4890,4889'),(4894,3,'K.1.2',4878,2,'K.1.2','K.1.2','4878,4876'),(4896,3,'K,1,2',4878,3,'K,1,2','K,1,2','4878,4876'),(4898,3,'K.1.2',4875,1,'K.1.2','K.1.2','4875,4874'),(4910,3,'K,1,2',4875,2,'K,1,2','K,1,2','4875,4874'),(4912,3,'null',4877,3,'null','','4877,4876'),(4915,3,'New child',4875,3,'New child','New child','4875,4874'),(4916,3,'New,child',4875,4,'New,child','New,child','4875,4874'),(4917,3,'Lab 1',4875,5,'Lab 1','Lab 1','4875,4874'),(4918,3,'Grade 6',4877,4,'Grade 6','Grade 6','4877,4876'),(4919,3,'Grade 7',4877,5,'Grade 7','Grade 7','4877,4876'),(4920,3,'Lab 2',4875,6,'Lab 2','Lab 2','4875,4874'),(4921,3,'SIB',4875,7,'SIB','','4875,4874'),(4922,4,'name2',4915,1,'name2','name2','4915,4875,4874'),(4923,4,'Reading-Literature',4880,1,'Reading-Literature','Reading-Literature','4880,4877,4876'),(4924,5,'ELA5&amp;RL.1',4923,1,'ELA5&amp;RL.1','ELA5&amp;RL.1','4923,4880,4877,4876');
/*!40000 ALTER TABLE `hierarchy_definition` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`pacific`@`localhost`*/ /*!50003 TRIGGER `hd_insert` AFTER INSERT ON `hierarchy_definition` FOR EACH ROW BEGIN
    CALL table_modified('hierarchy_definition');
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`pacific`@`localhost`*/ /*!50003 TRIGGER `hd_update` AFTER UPDATE ON `hierarchy_definition` FOR EACH ROW BEGIN
    CALL table_modified('hierarchy_definition');
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`pacific`@`localhost`*/ /*!50003 TRIGGER `hd_delete` AFTER DELETE ON `hierarchy_definition` FOR EACH ROW BEGIN
    CALL table_modified('hierarchy_definition');
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary table structure for view `hierarchy_definition_1_view`
--

DROP TABLE IF EXISTS `hierarchy_definition_1_view`;
/*!50001 DROP VIEW IF EXISTS `hierarchy_definition_1_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `hierarchy_definition_1_view` (
 `hd_id` tinyint NOT NULL,
  `hd_type` tinyint NOT NULL,
  `hd_value` tinyint NOT NULL,
  `hd_parent_id` tinyint NOT NULL,
  `hd_posn_in_parent` tinyint NOT NULL,
  `hd_std_desc` tinyint NOT NULL,
  `hd_extended_desc` tinyint NOT NULL,
  `hd_parent_path` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `inclusion_order`
--

DROP TABLE IF EXISTS `inclusion_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inclusion_order` (
  `io_id` int(10) NOT NULL AUTO_INCREMENT,
  `i_id` int(10) DEFAULT NULL,
  `p_id` int(10) DEFAULT NULL,
  `io_type` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`io_id`),
  KEY `idx_i_id` (`i_id`),
  KEY `idx_p_id` (`p_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inclusion_order`
--

LOCK TABLES `inclusion_order` WRITE;
/*!40000 ALTER TABLE `inclusion_order` DISABLE KEYS */;
/*!40000 ALTER TABLE `inclusion_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inclusion_order_element`
--

DROP TABLE IF EXISTS `inclusion_order_element`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inclusion_order_element` (
  `ioe_id` int(10) NOT NULL AUTO_INCREMENT,
  `io_id` int(10) NOT NULL,
  `ae_id` int(10) DEFAULT NULL,
  `ioe_sequence` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`ioe_id`),
  KEY `idx_inclusion_order` (`io_id`),
  KEY `idx_accessibility_elelement` (`ae_id`),
  CONSTRAINT `fk_ioe_accessibility_element` FOREIGN KEY (`ae_id`) REFERENCES `accessibility_element` (`ae_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ioe_inclusion_order` FOREIGN KEY (`io_id`) REFERENCES `inclusion_order` (`io_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inclusion_order_element`
--

LOCK TABLES `inclusion_order_element` WRITE;
/*!40000 ALTER TABLE `inclusion_order_element` DISABLE KEYS */;
/*!40000 ALTER TABLE `inclusion_order_element` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item`
--

DROP TABLE IF EXISTS `item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item` (
  `i_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `i_external_id` varchar(256) NOT NULL,
  `ib_id` int(10) unsigned NOT NULL,
  `i_type` tinyint(4) NOT NULL DEFAULT '0',
  `i_format` tinyint(4) NOT NULL,
  `i_description` varchar(100) DEFAULT NULL,
  `i_difficulty` tinyint(4) NOT NULL DEFAULT '0',
  `i_last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `i_last_edited_by` int(10) unsigned NOT NULL DEFAULT '0',
  `i_dev_state` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `i_xml_data` text NOT NULL,
  `i_response_cnt` int(10) unsigned NOT NULL DEFAULT '0',
  `i_notes` text,
  `i_review_lock` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `i_review_lifetime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `i_import_type` tinyint(4) NOT NULL DEFAULT '0',
  `i_lang` tinyint(4) NOT NULL DEFAULT '1',
  `i_correct_response` text,
  `i_author` int(10) unsigned NOT NULL DEFAULT '0',
  `i_royalties` varchar(80) DEFAULT NULL,
  `i_owner` varchar(80) DEFAULT NULL,
  `i_export_ok` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `i_source_document` varchar(160) DEFAULT NULL,
  `i_created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ip_id` int(11) unsigned DEFAULT NULL,
  `i_publication_status` tinyint(1) NOT NULL DEFAULT '0',
  `i_read_only` tinyint(1) NOT NULL DEFAULT '0',
  `i_ims_id` varchar(20) NOT NULL DEFAULT '0',
  `i_benchmark` varchar(10) DEFAULT NULL,
  `i_version` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `i_handle` varchar(20) NOT NULL DEFAULT '',
  `i_form_name` varchar(30) NOT NULL DEFAULT '',
  `i_form_session` tinyint(4) NOT NULL DEFAULT '0',
  `i_form_sequence` tinyint(4) NOT NULL DEFAULT '0',
  `i_last_save_user_id` int(10) unsigned NOT NULL,
  `i_due_date` date DEFAULT '0000-00-00',
  `i_readability_index` varchar(50) DEFAULT NULL,
  `i_is_pi_set` tinyint(4) NOT NULL,
  `i_qti_xml_data` text NOT NULL,
  `i_tei_data` text NOT NULL,
  `i_max_content_id` int(11) DEFAULT NULL,
  `i_stylesheet_url` varchar(255) DEFAULT NULL,
  `i_is_old_version` tinyint(4) DEFAULT NULL,
  `i_metadata_xml` text,
  `i_guid` text NOT NULL,
  PRIMARY KEY (`i_id`),
  KEY `EXTERNAL_ID` (`i_external_id`),
  KEY `TYPE` (`i_type`),
  KEY `ib_id` (`ib_id`),
  KEY `i_dev_state` (`i_dev_state`),
  KEY `i_review_lock` (`i_review_lock`),
  KEY `ip_id` (`ip_id`),
  KEY `i_read_only` (`i_read_only`),
  KEY `i_lang` (`i_lang`),
  KEY `i_version` (`i_version`),
  KEY `i_is_old_version` (`i_is_old_version`),
  KEY `i_ims_id` (`i_ims_id`),
  CONSTRAINT `item_fk_ib_id` FOREIGN KEY (`ib_id`) REFERENCES `item_bank` (`ib_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item`
--

LOCK TABLES `item` WRITE;
/*!40000 ALTER TABLE `item` DISABLE KEYS */;
/*!40000 ALTER TABLE `item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_alternate`
--

DROP TABLE IF EXISTS `item_alternate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_alternate` (
  `ia_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `i_id` int(10) unsigned NOT NULL,
  `ia_alternate_i_id` int(10) unsigned NOT NULL,
  `ia_adaptation_type` tinyint(4) NOT NULL,
  `ia_representation_form` tinyint(4) NOT NULL,
  `ia_language` varchar(2) NOT NULL,
  `ia_alternate_label` varchar(50) NOT NULL,
  PRIMARY KEY (`ia_id`),
  KEY `i_id` (`i_id`),
  KEY `ia_alternate_i_id` (`ia_alternate_i_id`),
  CONSTRAINT `item_alternate_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_alternate`
--

LOCK TABLES `item_alternate` WRITE;
/*!40000 ALTER TABLE `item_alternate` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_alternate` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_asset_attribute`
--

DROP TABLE IF EXISTS `item_asset_attribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_asset_attribute` (
  `iaa_id` int(11) NOT NULL AUTO_INCREMENT,
  `i_id` int(10) unsigned NOT NULL,
  `iaa_filename` varchar(60) NOT NULL DEFAULT '',
  `iaa_media_description` text,
  `iaa_source_url` varchar(200) NOT NULL DEFAULT '',
  `iaa_u_id` int(11) NOT NULL DEFAULT '0',
  `iaa_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `iaa_classification` varchar(5) DEFAULT NULL,
  PRIMARY KEY (`iaa_id`),
  KEY `i_id` (`i_id`),
  KEY `iaa_source_url` (`iaa_source_url`),
  KEY `iaa_u_id` (`iaa_u_id`),
  KEY `iaa_filename` (`iaa_filename`),
  KEY `iaa_timestamp` (`iaa_timestamp`),
  CONSTRAINT `item_asset_attribute_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_asset_attribute`
--

LOCK TABLES `item_asset_attribute` WRITE;
/*!40000 ALTER TABLE `item_asset_attribute` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_asset_attribute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_bank`
--

DROP TABLE IF EXISTS `item_bank`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_bank` (
  `ib_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `o_id` int(10) unsigned NOT NULL,
  `tb_id` int(10) unsigned NOT NULL,
  `ib_external_id` varchar(20) NOT NULL DEFAULT '',
  `ib_description` varchar(100) NOT NULL DEFAULT '',
  `ib_owner` varchar(30) NOT NULL DEFAULT '',
  `ib_version` date NOT NULL DEFAULT '0000-00-00',
  `ib_host_base` varchar(50) NOT NULL DEFAULT '',
  `ib_has_ims` tinyint(4) NOT NULL DEFAULT '0',
  `ib_assign_ims_id` tinyint(4) NOT NULL DEFAULT '0',
  `sh_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ib_importer_u_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`ib_id`),
  KEY `EXTERNAL_ID` (`ib_external_id`),
  KEY `tb_id` (`tb_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_bank`
--

LOCK TABLES `item_bank` WRITE;
/*!40000 ALTER TABLE `item_bank` DISABLE KEYS */;
INSERT INTO `item_bank` VALUES (15,1,8,'SBAC_Demo_Program','Demo program for SBAC testing purposes','SBAC','0000-00-00','http://cde.pacificmetrics.com/devcdesbac/gui/item.',0,0,18,4);
/*!40000 ALTER TABLE `item_bank` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_bank_metafiles`
--

DROP TABLE IF EXISTS `item_bank_metafiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_bank_metafiles` (
  `ibm_id` int(10) NOT NULL AUTO_INCREMENT,
  `ib_id` int(11) NOT NULL,
  `ibm_comment` text NOT NULL,
  `ibm_orig_name` varchar(255) NOT NULL,
  `ibm_system_name` varchar(255) NOT NULL,
  `ibm_type` varchar(50) NOT NULL,
  `ibm_version` tinyint(4) NOT NULL DEFAULT '0',
  `ibm_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ibm_original_id` int(10) DEFAULT NULL,
  `ibm_type_code` tinyint(4) DEFAULT NULL COMMENT '1 - item spec; 2 - passage spec; 3 - copyright; 4 - other',
  PRIMARY KEY (`ibm_id`,`ibm_version`),
  KEY `ib_id` (`ib_id`),
  KEY `ibm_timestamp` (`ibm_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_bank_metafiles`
--

LOCK TABLES `item_bank_metafiles` WRITE;
/*!40000 ALTER TABLE `item_bank_metafiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_bank_metafiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_bank_share`
--

DROP TABLE IF EXISTS `item_bank_share`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_bank_share` (
  `ibs_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ib_id` int(10) unsigned NOT NULL,
  `ibs_ib_share_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`ibs_id`),
  KEY `item_bank_share_ib_id` (`ib_id`),
  KEY `item_bank_share_ibs_ib_share_id` (`ibs_ib_share_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_bank_share`
--

LOCK TABLES `item_bank_share` WRITE;
/*!40000 ALTER TABLE `item_bank_share` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_bank_share` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_characterization`
--

DROP TABLE IF EXISTS `item_characterization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_characterization` (
  `i_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ic_type` int(10) unsigned NOT NULL DEFAULT '0',
  `ic_value` int(10) NOT NULL DEFAULT '0',
  `ic_value_str` varchar(150) DEFAULT NULL,
  KEY `ITEM_ID` (`i_id`),
  KEY `ID_TYPE` (`i_id`,`ic_type`),
  KEY `TYPE_VALUE` (`ic_type`,`ic_value`),
  CONSTRAINT `item_characterization_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_characterization`
--

LOCK TABLES `item_characterization` WRITE;
/*!40000 ALTER TABLE `item_characterization` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_characterization` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_comment`
--

DROP TABLE IF EXISTS `item_comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_comment` (
  `ic_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `i_id` int(10) unsigned NOT NULL,
  `u_id` int(11) NOT NULL,
  `ic_type` int(11) NOT NULL,
  `ic_dev_state` int(11) NOT NULL,
  `ic_rating` tinyint(4) NOT NULL,
  `ic_comment` text NOT NULL,
  `ic_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ic_id`),
  KEY `i_id` (`i_id`),
  KEY `u_id` (`u_id`),
  KEY `ic_type` (`ic_type`),
  CONSTRAINT `item_comment_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_comment`
--

LOCK TABLES `item_comment` WRITE;
/*!40000 ALTER TABLE `item_comment` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_comment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_format`
--

DROP TABLE IF EXISTS `item_format`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_format` (
  `itf_id` int(10) unsigned NOT NULL,
  `itf_name` varchar(50) NOT NULL,
  PRIMARY KEY (`itf_id`),
  KEY `idx_name` (`itf_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_format`
--

LOCK TABLES `item_format` WRITE;
/*!40000 ALTER TABLE `item_format` DISABLE KEYS */;
INSERT INTO `item_format` VALUES (3,'Activity Based'),(2,'Constructed Response'),(4,'Performance Task'),(1,'Selected Response');
/*!40000 ALTER TABLE `item_format` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_fragment`
--

DROP TABLE IF EXISTS `item_fragment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_fragment` (
  `if_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `i_id` int(10) unsigned NOT NULL,
  `ii_id` int(11) unsigned NOT NULL,
  `if_type` tinyint(3) unsigned NOT NULL,
  `if_set_seq` tinyint(3) unsigned NOT NULL,
  `if_seq` tinyint(3) unsigned NOT NULL,
  `if_identifier` varchar(100) DEFAULT NULL,
  `if_text` text NOT NULL,
  `if_attribute_list` text,
  `if_audio_url` varchar(255) NOT NULL,
  PRIMARY KEY (`if_id`),
  KEY `i_id` (`i_id`),
  KEY `if_type` (`if_type`),
  KEY `if_seq` (`if_seq`),
  KEY `if_set_seq` (`if_set_seq`),
  CONSTRAINT `item_fragment_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_fragment`
--

LOCK TABLES `item_fragment` WRITE;
/*!40000 ALTER TABLE `item_fragment` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_fragment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_import_action`
--

DROP TABLE IF EXISTS `item_import_action`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_import_action` (
  `ua_id` int(11) NOT NULL,
  `i_id` int(11) NOT NULL,
  `iia_type` tinyint(4) NOT NULL,
  KEY `ua_id` (`ua_id`),
  KEY `i_id` (`i_id`),
  KEY `iia_type` (`iia_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_import_action`
--

LOCK TABLES `item_import_action` WRITE;
/*!40000 ALTER TABLE `item_import_action` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_import_action` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_import_monitor`
--

DROP TABLE IF EXISTS `item_import_monitor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_import_monitor` (
  `iim_id` int(11) NOT NULL AUTO_INCREMENT,
  `ib_id` int(10) unsigned NOT NULL,
  `u_id` int(11) NOT NULL,
  `ua_id` int(11) NOT NULL,
  `iim_status` tinyint(4) NOT NULL,
  `iim_status_detail` varchar(255) NOT NULL,
  `iim_dev_state` tinyint(4) NOT NULL,
  `iim_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `iim_import_file_name` varchar(255) NOT NULL,
  `iim_import_file_modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`iim_id`),
  KEY `ib_id` (`ib_id`),
  KEY `item_import_monitor_u_id` (`u_id`),
  KEY `item_import_monitor_ua_id` (`ua_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_import_monitor`
--

LOCK TABLES `item_import_monitor` WRITE;
/*!40000 ALTER TABLE `item_import_monitor` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_import_monitor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_interaction`
--

DROP TABLE IF EXISTS `item_interaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_interaction` (
  `ii_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ii_name` varchar(50) NOT NULL,
  `i_id` int(10) unsigned NOT NULL,
  `ii_type` tinyint(4) NOT NULL,
  `ii_max_score` float NOT NULL,
  `ii_score_type` tinyint(4) NOT NULL,
  `ii_correct` varchar(100) DEFAULT NULL,
  `ii_correct_map` text,
  `ii_attribute_list` text,
  PRIMARY KEY (`ii_id`),
  KEY `item_interaction_fk_i_id` (`i_id`),
  CONSTRAINT `item_interaction_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_interaction`
--

LOCK TABLES `item_interaction` WRITE;
/*!40000 ALTER TABLE `item_interaction` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_interaction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_metafile_association`
--

DROP TABLE IF EXISTS `item_metafile_association`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_metafile_association` (
  `ima_id` int(10) NOT NULL AUTO_INCREMENT,
  `i_id` int(10) unsigned NOT NULL,
  `ibm_id` int(10) NOT NULL,
  `ibm_version` int(10) NOT NULL,
  PRIMARY KEY (`ima_id`),
  UNIQUE KEY `idx_item_metafile` (`i_id`,`ibm_id`),
  KEY `idx_metafile` (`ibm_id`),
  CONSTRAINT `FK_ima_item` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_metafile_association`
--

LOCK TABLES `item_metafile_association` WRITE;
/*!40000 ALTER TABLE `item_metafile_association` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_metafile_association` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_metafiles`
--

DROP TABLE IF EXISTS `item_metafiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_metafiles` (
  `im_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `i_id` int(10) unsigned NOT NULL DEFAULT '0',
  `u_id` int(10) unsigned NOT NULL DEFAULT '0',
  `i_dev_state` tinyint(4) NOT NULL DEFAULT '0',
  `im_filename` varchar(255) NOT NULL DEFAULT '',
  `im_timestamp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `im_comment` text NOT NULL,
  PRIMARY KEY (`im_id`),
  KEY `i_id` (`i_id`),
  KEY `u_id` (`u_id`),
  KEY `im_timestamp` (`im_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_metafiles`
--

LOCK TABLES `item_metafiles` WRITE;
/*!40000 ALTER TABLE `item_metafiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_metafiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_project`
--

DROP TABLE IF EXISTS `item_project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_project` (
  `ip_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ib_id` int(11) unsigned NOT NULL DEFAULT '0',
  `ip_name` varchar(50) NOT NULL DEFAULT '',
  `ip_description` varchar(160) DEFAULT NULL,
  PRIMARY KEY (`ip_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_project`
--

LOCK TABLES `item_project` WRITE;
/*!40000 ALTER TABLE `item_project` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_project` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `item_report_view`
--

DROP TABLE IF EXISTS `item_report_view`;
/*!50001 DROP VIEW IF EXISTS `item_report_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `item_report_view` (
 `ItemBankId` tinyint NOT NULL,
  `ItemBankExternalId` tinyint NOT NULL,
  `ItemExternalId` tinyint NOT NULL,
  `ContentAreaId` tinyint NOT NULL,
  `ContentAreaName` tinyint NOT NULL,
  `GradeLevel` tinyint NOT NULL,
  `GradeFrom` tinyint NOT NULL,
  `GradeTo` tinyint NOT NULL,
  `GradeSpan` tinyint NOT NULL,
  `ItemFormatName` tinyint NOT NULL,
  `DevStateName` tinyint NOT NULL,
  `DifficultyName` tinyint NOT NULL,
  `PublicationStatusName` tinyint NOT NULL,
  `ItemWriter` tinyint NOT NULL,
  `ReadabilityIndex` tinyint NOT NULL,
  `ItemDescription` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `item_status`
--

DROP TABLE IF EXISTS `item_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_status` (
  `is_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `i_id` int(10) unsigned NOT NULL DEFAULT '0',
  `is_last_dev_state` tinyint(3) NOT NULL DEFAULT '0',
  `is_new_dev_state` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `is_timestamp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `is_accepted_timestamp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `is_u_id` int(10) unsigned NOT NULL DEFAULT '0',
  `i_xml_data` text NOT NULL,
  `i_notes` text,
  `i_qti_xml_data` text,
  `i_tei_data` text,
  `ib_id` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`is_id`),
  KEY `i_id` (`i_id`),
  KEY `is_last_dev_state` (`is_last_dev_state`),
  KEY `is_new_dev_state` (`is_new_dev_state`),
  KEY `is_u_id` (`is_u_id`),
  KEY `i_notes` (`i_notes`(5)),
  CONSTRAINT `item_status_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_status`
--

LOCK TABLES `item_status` WRITE;
/*!40000 ALTER TABLE `item_status` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_status_fragment`
--

DROP TABLE IF EXISTS `item_status_fragment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_status_fragment` (
  `isf_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `is_id` int(10) unsigned NOT NULL,
  `i_id` int(10) unsigned NOT NULL,
  `if_id` int(10) unsigned NOT NULL,
  `isf_text` text,
  PRIMARY KEY (`isf_id`),
  KEY `item_status_fragment_fk_i_id` (`i_id`),
  CONSTRAINT `item_status_fragment_fk_i_id` FOREIGN KEY (`i_id`) REFERENCES `item` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_status_fragment`
--

LOCK TABLES `item_status_fragment` WRITE;
/*!40000 ALTER TABLE `item_status_fragment` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_status_fragment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_type`
--

DROP TABLE IF EXISTS `item_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `item_type` (
  `it_id` int(10) NOT NULL,
  `it_name` varchar(30) NOT NULL,
  PRIMARY KEY (`it_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_type`
--

LOCK TABLES `item_type` WRITE;
/*!40000 ALTER TABLE `item_type` DISABLE KEYS */;
INSERT INTO `item_type` VALUES (1,'SR, exclusive'),(2,'SR, non-exclusive'),(3,'CR, single-line'),(4,'CR, multi-line'),(5,'Bubble/Grid'),(6,'Interactive'),(23,'CR, multi-entry, single-line'),(24,'CR, multi-entry, multi-line');
/*!40000 ALTER TABLE `item_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `languages`
--

DROP TABLE IF EXISTS `languages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `languages` (
  `l_code` char(5) NOT NULL,
  `l_name` varchar(30) NOT NULL,
  PRIMARY KEY (`l_code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `languages`
--

LOCK TABLES `languages` WRITE;
/*!40000 ALTER TABLE `languages` DISABLE KEYS */;
INSERT INTO `languages` VALUES ('aa','Afar'),('ab','Abkhazian'),('af','Afrikaans'),('am','Amharic'),('an','Aragonese'),('ar','Arabic'),('as','Assamese'),('ay','Aymara'),('az','Azerbaijani'),('ba','Bashkir'),('be','Byelorussian (Belarusian)'),('bg','Bulgarian'),('bh','Bihari'),('bi','Bislama'),('bn','Bengali (Bangla)'),('bo','Tibetan'),('br','Breton'),('ca','Catalan'),('co','Corsican'),('cs','Czech'),('cy','Welsh'),('da','Danish'),('de','German'),('dz','Bhutani'),('el','Greek'),('en','English'),('eo','Esperanto'),('es','Spanish'),('et','Estonian'),('eu','Basque'),('fa','Farsi'),('fi','Finnish'),('fj','Fiji'),('fo','Faeroese'),('fr','French'),('fy','Frisian'),('ga','Irish'),('gd','Gaelic (Scottish)'),('gl','Galician'),('gn','Guarani'),('gu','Gujarati'),('gv','Gaelic (Manx)'),('ha','Hausa'),('he','Hebrew'),('hi','Hindi'),('hr','Croatian'),('ht','Haitian Creole'),('hu','Hungarian'),('hy','Armenian'),('ia','Interlingua'),('id','Indonesian'),('ie','Interlingue'),('ii','Sichuan Yi'),('ik','Inupiak'),('io','Ido'),('is','Icelandic'),('it','Italian'),('iu','Inuktitut'),('ja','Japanese'),('jv','Javanese'),('ka','Georgian'),('kk','Kazakh'),('kl','Greenlandic'),('km','Cambodian'),('kn','Kannada'),('ko','Korean'),('ks','Kashmiri'),('ku','Kurdish'),('ky','Kirghiz'),('la','Latin'),('li','Limburgish ( Limburger)'),('ln','Lingala'),('lo','Laothian'),('lt','Lithuanian'),('lv','Latvian (Lettish)'),('mg','Malagasy'),('mi','Maori'),('mk','Macedonian'),('ml','Malayalam'),('mn','Mongolian'),('mo','Moldavian'),('mr','Marathi'),('ms','Malay'),('mt','Maltese'),('my','Burmese'),('na','Nauru'),('ne','Nepali'),('nl','Dutch'),('no','Norwegian'),('oc','Occitan'),('om','Oromo (Afan, Galla)'),('or','Oriya'),('pa','Punjabi'),('pl','Polish'),('ps','Pashto (Pushto)'),('pt','Portuguese'),('qu','Quechua'),('rm','Rhaeto-Romance'),('rn','Kirundi (Rundi)'),('ro','Romanian'),('ru','Russian'),('rw','Kinyarwanda (Ruanda)'),('sa','Sanskrit'),('sd','Sindhi'),('sg','Sangro'),('sh','Serbo-Croatian'),('si','Sinhalese'),('sk','Slovak'),('sl','Slovenian'),('sm','Samoan'),('sn','Shona'),('so','Somali'),('sq','Albanian'),('sr','Serbian'),('ss','Siswati'),('st','Sesotho'),('su','Sundanese'),('sv','Swedish'),('sw','Swahili (Kiswahili)'),('ta','Tamil'),('te','Telugu'),('tg','Tajik'),('th','Thai'),('ti','Tigrinya'),('tk','Turkmen'),('tl','Tagalog'),('tn','Setswana'),('to','Tonga'),('tr','Turkish'),('ts','Tsonga'),('tt','Tatar'),('tw','Twi'),('ug','Uighur'),('uk','Ukrainian'),('ur','Urdu'),('uz','Uzbek'),('vi','Vietnamese'),('vo','Volapk'),('wa','Wallon'),('wo','Wolof'),('xh','Xhosa'),('yi','Yiddish'),('yo','Yoruba'),('zh','Chinese (Traditional)'),('zu','Zulu');
/*!40000 ALTER TABLE `languages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `last_modification`
--

DROP TABLE IF EXISTS `last_modification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `last_modification` (
  `lm_id` int(10) NOT NULL AUTO_INCREMENT,
  `lm_table_name` varchar(50) NOT NULL,
  `lm_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`lm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `last_modification`
--

LOCK TABLES `last_modification` WRITE;
/*!40000 ALTER TABLE `last_modification` DISABLE KEYS */;
/*!40000 ALTER TABLE `last_modification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `metadata_lookup`
--

DROP TABLE IF EXISTS `metadata_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metadata_lookup` (
  `ml_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ml_value` varchar(50) NOT NULL,
  `ml_code` int(10) DEFAULT NULL,
  PRIMARY KEY (`ml_id`),
  KEY `idx_value` (`ml_value`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metadata_lookup`
--

LOCK TABLES `metadata_lookup` WRITE;
/*!40000 ALTER TABLE `metadata_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `metadata_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `metadata_mapping`
--

DROP TABLE IF EXISTS `metadata_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metadata_mapping`
--

LOCK TABLES `metadata_mapping` WRITE;
/*!40000 ALTER TABLE `metadata_mapping` DISABLE KEYS */;
INSERT INTO `metadata_mapping` VALUES (1,4,'/general/descriptions/strings/@value','i_description',NULL,NULL,NULL,NULL,NULL),(2,4,'/educational/difficulty/@value','i_difficulty',NULL,'difficulty','d_name',NULL,'d_id'),(3,4,'/educational/interactivityType/@value',NULL,101,'metadata_lookup','ml_value','Interactivity:','ml_code');
/*!40000 ALTER TABLE `metadata_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `object_characterization`
--

DROP TABLE IF EXISTS `object_characterization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `object_characterization` (
  `oc_object_type` int(10) unsigned NOT NULL DEFAULT '0',
  `oc_object_id` int(10) unsigned NOT NULL DEFAULT '0',
  `oc_characteristic` int(10) unsigned NOT NULL DEFAULT '0',
  `oc_int_value` int(11) NOT NULL DEFAULT '0',
  KEY `OBJECT_TYPE_ID` (`oc_object_type`,`oc_object_id`),
  KEY `OBJECT_TYPE_ID_CHRSTC` (`oc_object_type`,`oc_object_id`,`oc_characteristic`),
  KEY `TYPE` (`oc_object_type`),
  KEY `EVERYTHING` (`oc_object_type`,`oc_object_id`,`oc_characteristic`,`oc_int_value`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `object_characterization`
--

LOCK TABLES `object_characterization` WRITE;
/*!40000 ALTER TABLE `object_characterization` DISABLE KEYS */;
/*!40000 ALTER TABLE `object_characterization` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organization`
--

DROP TABLE IF EXISTS `organization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organization` (
  `o_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `o_name` varchar(40) NOT NULL,
  `o_description` varchar(255) NOT NULL,
  PRIMARY KEY (`o_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organization`
--

LOCK TABLES `organization` WRITE;
/*!40000 ALTER TABLE `organization` DISABLE KEYS */;
INSERT INTO `organization` VALUES (1,'SBAC','Consortium-level organization');
/*!40000 ALTER TABLE `organization` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage`
--

DROP TABLE IF EXISTS `passage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage` (
  `p_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `p_name` varchar(60) NOT NULL DEFAULT '',
  `ib_id` int(10) unsigned NOT NULL,
  `p_genre` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `p_subgenre` varchar(30) DEFAULT NULL,
  `p_topic` varchar(40) DEFAULT NULL,
  `p_reading_level` text,
  `p_summary` text,
  `p_word_count` int(10) unsigned NOT NULL DEFAULT '0',
  `p_url` varchar(255) NOT NULL DEFAULT '',
  `p_cross_curriculum` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `p_char_ethnicity` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `p_char_gender` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `p_notes` text,
  `p_button_name` varchar(30) DEFAULT NULL,
  `p_code` varchar(4) NOT NULL DEFAULT '',
  `p_lang` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `p_dev_state` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `p_author` int(10) unsigned NOT NULL DEFAULT '0',
  `p_review_lock` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `p_review_lifetime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ip_id` int(10) unsigned NOT NULL DEFAULT '0',
  `audio_script` longtext,
  `audio_file_url` varchar(254) DEFAULT NULL,
  `audio_comments` longtext,
  `p_last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `p_audio_modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `p_is_pi_set` tinyint(4) NOT NULL,
  `p_readability_index` varchar(50) NOT NULL,
  `p_publication_status` tinyint(4) NOT NULL,
  `p_max_content_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`p_id`),
  KEY `p_name` (`p_name`),
  KEY `ib_id` (`ib_id`),
  KEY `p_dev_state` (`p_dev_state`),
  KEY `p_review_lock` (`p_review_lock`),
  KEY `p_lang` (`p_lang`),
  KEY `p_code` (`p_code`),
  CONSTRAINT `passage_fk_ib_id` FOREIGN KEY (`ib_id`) REFERENCES `item_bank` (`ib_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage`
--

LOCK TABLES `passage` WRITE;
/*!40000 ALTER TABLE `passage` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_comment`
--

DROP TABLE IF EXISTS `passage_comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_comment` (
  `pc_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `p_id` int(11) NOT NULL,
  `u_id` int(11) NOT NULL,
  `pc_type` int(11) NOT NULL,
  `pc_dev_state` int(11) NOT NULL,
  `pc_rating` tinyint(4) NOT NULL,
  `pc_comment` text NOT NULL,
  `pc_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`pc_id`),
  KEY `idx_p_id` (`p_id`),
  KEY `idx_u_id` (`u_id`),
  KEY `idx_pc_type` (`pc_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_comment`
--

LOCK TABLES `passage_comment` WRITE;
/*!40000 ALTER TABLE `passage_comment` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_comment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_item_set`
--

DROP TABLE IF EXISTS `passage_item_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_item_set` (
  `pis_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `p_id` int(10) unsigned NOT NULL DEFAULT '0',
  `i_id` int(10) unsigned NOT NULL DEFAULT '0',
  `pis_sequence` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`pis_id`),
  KEY `p_id` (`p_id`),
  KEY `i_id` (`i_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_item_set`
--

LOCK TABLES `passage_item_set` WRITE;
/*!40000 ALTER TABLE `passage_item_set` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_item_set` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_media`
--

DROP TABLE IF EXISTS `passage_media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_media` (
  `pm_id` int(10) NOT NULL AUTO_INCREMENT,
  `p_id` int(10) NOT NULL DEFAULT '0',
  `pm_clnt_filename` varchar(60) NOT NULL DEFAULT '',
  `pm_srvr_filename` varchar(60) NOT NULL DEFAULT '',
  `pm_description` text,
  `pm_u_id` int(10) NOT NULL DEFAULT '0',
  `pm_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`pm_id`),
  KEY `idx_i_id` (`p_id`),
  KEY `idx_pm_clnt_filename` (`pm_clnt_filename`),
  KEY `idx_pm_u_id` (`pm_u_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_media`
--

LOCK TABLES `passage_media` WRITE;
/*!40000 ALTER TABLE `passage_media` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_media` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_metafile_association`
--

DROP TABLE IF EXISTS `passage_metafile_association`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_metafile_association` (
  `pma_id` int(10) NOT NULL AUTO_INCREMENT,
  `p_id` int(10) unsigned NOT NULL,
  `ibm_id` int(10) NOT NULL,
  `ibm_version` int(10) NOT NULL,
  PRIMARY KEY (`pma_id`),
  UNIQUE KEY `idx_passage_metafile` (`p_id`,`ibm_id`),
  KEY `idx_metafile` (`ibm_id`),
  CONSTRAINT `FK_pma_passage` FOREIGN KEY (`p_id`) REFERENCES `passage` (`p_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_metafile_association`
--

LOCK TABLES `passage_metafile_association` WRITE;
/*!40000 ALTER TABLE `passage_metafile_association` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_metafile_association` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_metafiles`
--

DROP TABLE IF EXISTS `passage_metafiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_metafiles` (
  `pm_id` int(11) NOT NULL AUTO_INCREMENT,
  `p_id` int(11) NOT NULL DEFAULT '0',
  `u_id` int(11) NOT NULL DEFAULT '0',
  `p_dev_state` tinyint(4) NOT NULL DEFAULT '0',
  `pm_filename` varchar(255) NOT NULL DEFAULT '',
  `pm_timestamp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `pm_comment` text NOT NULL,
  PRIMARY KEY (`pm_id`),
  KEY `u_id` (`u_id`),
  KEY `pm_timestamp` (`pm_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_metafiles`
--

LOCK TABLES `passage_metafiles` WRITE;
/*!40000 ALTER TABLE `passage_metafiles` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_metafiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_set`
--

DROP TABLE IF EXISTS `passage_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_set` (
  `ps_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ps_name` varchar(50) NOT NULL,
  `ib_id` int(10) unsigned NOT NULL,
  `ps_description` varchar(100) NOT NULL,
  PRIMARY KEY (`ps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_set`
--

LOCK TABLES `passage_set` WRITE;
/*!40000 ALTER TABLE `passage_set` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_set` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_set_list`
--

DROP TABLE IF EXISTS `passage_set_list`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_set_list` (
  `psl_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ps_id` int(10) unsigned NOT NULL,
  `p_id` int(10) unsigned NOT NULL,
  `psl_sequence` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`psl_id`),
  KEY `ps_id` (`ps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_set_list`
--

LOCK TABLES `passage_set_list` WRITE;
/*!40000 ALTER TABLE `passage_set_list` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_set_list` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `passage_status`
--

DROP TABLE IF EXISTS `passage_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passage_status` (
  `ps_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `p_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ps_last_dev_state` tinyint(3) NOT NULL DEFAULT '0',
  `ps_new_dev_state` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `ps_timestamp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ps_accepted_timestamp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ps_u_id` int(10) unsigned NOT NULL DEFAULT '0',
  `p_content` text NOT NULL,
  `p_notes` text NOT NULL,
  `ps_footnotes` text NOT NULL,
  `ib_id` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ps_id`),
  KEY `p_id` (`p_id`),
  KEY `ps_last_dev_state` (`ps_last_dev_state`),
  KEY `ps_new_dev_state` (`ps_new_dev_state`),
  KEY `ps_u_id` (`ps_u_id`),
  KEY `ps_timestamp` (`ps_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `passage_status`
--

LOCK TABLES `passage_status` WRITE;
/*!40000 ALTER TABLE `passage_status` DISABLE KEYS */;
/*!40000 ALTER TABLE `passage_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `publication_status`
--

DROP TABLE IF EXISTS `publication_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `publication_status` (
  `ps_id` int(10) NOT NULL,
  `ps_name` varchar(100) NOT NULL,
  PRIMARY KEY (`ps_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publication_status`
--

LOCK TABLES `publication_status` WRITE;
/*!40000 ALTER TABLE `publication_status` DISABLE KEYS */;
INSERT INTO `publication_status` VALUES (0,'Unused'),(1,'Field Test'),(2,'Embedded Field Test'),(3,'Operational'),(4,'Field Tested'),(5,'Pilot'),(6,'Equating'),(7,'Released'),(8,'Ready for Operational'),(9,'Ready for Field Test'),(10,'Ready for Pilot Test'),(11,'Pilot Tested'),(12,'Ready for Field Review'),(13,'Field Reviewed'),(14,'Operational Equating'),(15,'Rejected');
/*!40000 ALTER TABLE `publication_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `qualifier_label`
--

DROP TABLE IF EXISTS `qualifier_label`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `qualifier_label` (
  `sh_id` int(10) unsigned NOT NULL DEFAULT '0',
  `ql_type` int(10) unsigned NOT NULL DEFAULT '0',
  `ql_label` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`sh_id`,`ql_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qualifier_label`
--

LOCK TABLES `qualifier_label` WRITE;
/*!40000 ALTER TABLE `qualifier_label` DISABLE KEYS */;
INSERT INTO `qualifier_label` VALUES (17,1,'Hierarchy'),(17,2,'Test Subject'),(17,3,'Area'),(17,4,'General Content'),(17,5,'Specific Content'),(17,6,'Sub-Specific Content'),(18,1,'Hierarchy'),(18,2,'Test Subject'),(18,3,'Area'),(18,4,'General Content'),(18,5,'Specific Content'),(18,6,'Sub-Specific Content'),(20,1,'Hierarchy'),(20,2,'Test Subject'),(20,3,'Area'),(20,4,'General Content'),(20,5,'Specific Content'),(20,6,'Sub-Specific Content'),(21,1,'Hierarchy'),(21,2,'Test Subject'),(21,3,'Area'),(21,4,'General Content'),(21,5,'Specific Content'),(21,6,'Sub-Specific Content');
/*!40000 ALTER TABLE `qualifier_label` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scoring_rubric`
--

DROP TABLE IF EXISTS `scoring_rubric`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scoring_rubric` (
  `sr_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ib_id` int(10) unsigned NOT NULL DEFAULT '0',
  `sr_name` varchar(40) NOT NULL DEFAULT '',
  `sr_description` text NOT NULL,
  `sr_url` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`sr_id`),
  KEY `ib_id` (`ib_id`),
  KEY `sr_name` (`sr_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scoring_rubric`
--

LOCK TABLES `scoring_rubric` WRITE;
/*!40000 ALTER TABLE `scoring_rubric` DISABLE KEYS */;
/*!40000 ALTER TABLE `scoring_rubric` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `single_item_view`
--

DROP TABLE IF EXISTS `single_item_view`;
/*!50001 DROP VIEW IF EXISTS `single_item_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `single_item_view` (
 `i_id` tinyint NOT NULL,
  `i_external_id` tinyint NOT NULL,
  `i_description` tinyint NOT NULL,
  `item_bank` tinyint NOT NULL,
  `points` tinyint NOT NULL,
  `grade_level` tinyint NOT NULL,
  `grade_span_start` tinyint NOT NULL,
  `grade_span_end` tinyint NOT NULL,
  `content_area` tinyint NOT NULL,
  `item_type` tinyint NOT NULL,
  `publication_status` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `single_item_view_with_content`
--

DROP TABLE IF EXISTS `single_item_view_with_content`;
/*!50001 DROP VIEW IF EXISTS `single_item_view_with_content`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `single_item_view_with_content` (
 `i_id` tinyint NOT NULL,
  `i_external_id` tinyint NOT NULL,
  `i_description` tinyint NOT NULL,
  `item_bank` tinyint NOT NULL,
  `points` tinyint NOT NULL,
  `grade_level` tinyint NOT NULL,
  `content_area` tinyint NOT NULL,
  `item_type` tinyint NOT NULL,
  `publication_status` tinyint NOT NULL,
  `i_html` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `standard_hierarchy`
--

DROP TABLE IF EXISTS `standard_hierarchy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `standard_hierarchy` (
  `sh_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sh_external_id` varchar(20) DEFAULT NULL,
  `sh_name` varchar(50) NOT NULL DEFAULT '',
  `sh_description` varchar(255) NOT NULL DEFAULT '',
  `sh_released` date NOT NULL DEFAULT '0000-00-00',
  `sh_source` varchar(50) NOT NULL DEFAULT '',
  `hd_id` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`sh_id`),
  KEY `EXTERNAL_ID` (`sh_external_id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `standard_hierarchy`
--

LOCK TABLES `standard_hierarchy` WRITE;
/*!40000 ALTER TABLE `standard_hierarchy` DISABLE KEYS */;
INSERT INTO `standard_hierarchy` VALUES (18,'CCS','Common Core State Standards','The Common Core State Standard hierarchy','0000-00-00','',4876);
/*!40000 ALTER TABLE `standard_hierarchy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `stat_admin_item_value_view`
--

DROP TABLE IF EXISTS `stat_admin_item_value_view`;
/*!50001 DROP VIEW IF EXISTS `stat_admin_item_value_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `stat_admin_item_value_view` (
 `i_id` tinyint NOT NULL,
  `sa_id` tinyint NOT NULL,
  `value1` tinyint NOT NULL,
  `value2` tinyint NOT NULL,
  `value3` tinyint NOT NULL,
  `value4` tinyint NOT NULL,
  `value5` tinyint NOT NULL,
  `value6` tinyint NOT NULL,
  `value7` tinyint NOT NULL,
  `value8` tinyint NOT NULL,
  `value9` tinyint NOT NULL,
  `value10` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `stat_administration`
--

DROP TABLE IF EXISTS `stat_administration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stat_administration`
--

LOCK TABLES `stat_administration` WRITE;
/*!40000 ALTER TABLE `stat_administration` DISABLE KEYS */;
/*!40000 ALTER TABLE `stat_administration` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `stat_administration_item_view`
--

DROP TABLE IF EXISTS `stat_administration_item_view`;
/*!50001 DROP VIEW IF EXISTS `stat_administration_item_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `stat_administration_item_view` (
 `sa_id` tinyint NOT NULL,
  `i_id` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `stat_administration_status`
--

DROP TABLE IF EXISTS `stat_administration_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stat_administration_status` (
  `sas_id` int(10) NOT NULL,
  `sas_name` varchar(50) NOT NULL,
  PRIMARY KEY (`sas_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stat_administration_status`
--

LOCK TABLES `stat_administration_status` WRITE;
/*!40000 ALTER TABLE `stat_administration_status` DISABLE KEYS */;
INSERT INTO `stat_administration_status` VALUES (0,'Undefined'),(1,'Success'),(2,'Partial'),(3,'Failure'),(4,'Active'),(5,'Inactive'),(6,'Archive');
/*!40000 ALTER TABLE `stat_administration_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stat_administration_value`
--

DROP TABLE IF EXISTS `stat_administration_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stat_administration_value`
--

LOCK TABLES `stat_administration_value` WRITE;
/*!40000 ALTER TABLE `stat_administration_value` DISABLE KEYS */;
/*!40000 ALTER TABLE `stat_administration_value` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stat_item_value`
--

DROP TABLE IF EXISTS `stat_item_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stat_item_value`
--

LOCK TABLES `stat_item_value` WRITE;
/*!40000 ALTER TABLE `stat_item_value` DISABLE KEYS */;
/*!40000 ALTER TABLE `stat_item_value` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stat_key`
--

DROP TABLE IF EXISTS `stat_key`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stat_key` (
  `sk_id` int(10) NOT NULL AUTO_INCREMENT,
  `sk_name` varchar(20) NOT NULL,
  `sk_description` varchar(100) DEFAULT NULL,
  `sk_type` varchar(20) NOT NULL,
  `sk_domain` int(2) DEFAULT NULL COMMENT '1 = item statistic, 2 = administration statistic, 3 = both',
  PRIMARY KEY (`sk_id`),
  KEY `idx_sk_name` (`sk_name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stat_key`
--

LOCK TABLES `stat_key` WRITE;
/*!40000 ALTER TABLE `stat_key` DISABLE KEYS */;
INSERT INTO `stat_key` VALUES (1,'P-Val',NULL,'float',1),(2,'Adj P-Val',NULL,'float',1),(3,'BIS',NULL,'float',1),(4,'BIS Rmv',NULL,'float',1),(5,'% Missing',NULL,'float',1),(6,'Ext Val 1',NULL,'float',3),(7,'Ext Val 2',NULL,'float',3),(8,'Ext Val 3',NULL,'float',3),(9,'Ext Val 4',NULL,'float',3),(10,'Ext Val 5',NULL,'float',3);
/*!40000 ALTER TABLE `stat_key` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `stat_key_name_view`
--

DROP TABLE IF EXISTS `stat_key_name_view`;
/*!50001 DROP VIEW IF EXISTS `stat_key_name_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `stat_key_name_view` (
 `name1` tinyint NOT NULL,
  `name2` tinyint NOT NULL,
  `name3` tinyint NOT NULL,
  `name4` tinyint NOT NULL,
  `name5` tinyint NOT NULL,
  `name6` tinyint NOT NULL,
  `name7` tinyint NOT NULL,
  `name8` tinyint NOT NULL,
  `name9` tinyint NOT NULL,
  `name10` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `stat_key_value`
--

DROP TABLE IF EXISTS `stat_key_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stat_key_value` (
  `skv_id` int(10) NOT NULL AUTO_INCREMENT,
  `sk_id` int(10) NOT NULL,
  `skv_value` varchar(50) NOT NULL,
  PRIMARY KEY (`skv_id`),
  KEY `idx_sk_id` (`sk_id`),
  CONSTRAINT `PK_skv_sk` FOREIGN KEY (`sk_id`) REFERENCES `stat_key` (`sk_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stat_key_value`
--

LOCK TABLES `stat_key_value` WRITE;
/*!40000 ALTER TABLE `stat_key_value` DISABLE KEYS */;
/*!40000 ALTER TABLE `stat_key_value` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `u_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `u_external_id` int(10) unsigned DEFAULT NULL,
  `u_username` varchar(30) NOT NULL DEFAULT '',
  `u_password` varchar(64) NOT NULL DEFAULT '',
  `u_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `u_active` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `u_last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `u_deleted` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `u_del_date_time` datetime DEFAULT NULL,
  `u_permissions` int(10) unsigned NOT NULL DEFAULT '0',
  `o_id` int(10) unsigned NOT NULL,
  `u_admin_type` tinyint(3) unsigned NOT NULL,
  `u_review_type` tinyint(3) unsigned NOT NULL,
  `u_title` varchar(4) NOT NULL DEFAULT '',
  `u_first_name` varchar(35) NOT NULL DEFAULT '',
  `u_middle_name` varchar(35) NOT NULL DEFAULT '',
  `u_last_name` varchar(35) NOT NULL DEFAULT '',
  `u_suffix` char(3) NOT NULL DEFAULT '',
  `u_phone` varchar(15) NOT NULL DEFAULT '',
  `u_email` varchar(45) NOT NULL DEFAULT '',
  `u_writer_code` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`u_id`),
  UNIQUE KEY `USERNAME` (`u_username`),
  UNIQUE KEY `USERNAME_PASSWORD` (`u_username`,`u_password`),
  KEY `EXTERNAL_ID` (`u_external_id`),
  KEY `TYPE` (`u_type`),
  KEY `DELETED` (`u_deleted`),
  KEY `ACTIVE` (`u_active`),
  KEY `o_id` (`o_id`),
  KEY `u_review_type` (`u_review_type`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,NULL,'system','$apr1$uU46CBSP$W1lq7k2klKyuR.yIXyFEq0',11,1,'2014-04-24 19:32:13',0,NULL,208,1,1,2,'','System','','Super Admin','','','sbac07pacmetteams@pacificmetrics.com','System1'),(2,0,'ws-user-1','$apr1$lz4Mm2t6$pHexWtZ2HsRwhIvCCkMRE0',12,1,'2013-01-24 10:44:45',0,NULL,0,0,0,0,'','webservice','user','one','','','IAIPhelp@pacificmetrics.com',''),(3,0,'ws-user-2','$apr1$xEf0H0bT$pzj.0lkMvbcl26hlMv688/',12,1,'2013-01-24 12:11:41',0,NULL,0,0,0,0,'','','','','','','IAIPhelp@pacificmetrics.com',''),(4,NULL,'cdesbac15','$apr1$QRg/eZZa$pmNNjD3E/ARpgh7nT.LHR1',11,1,'2014-04-24 19:33:10',0,NULL,0,1,0,0,'','Item','','Importer','','','cde@pacificmetrics.com',''),(5,NULL,'jenchamberlain','$apr1$SaX/1YMP$uDcY.HNJ3wSHj1WiNYHvd.',11,1,'2014-04-24 19:36:01',0,NULL,1,1,1,2,'','Jennifer','','Isaacs','','','jisaacs@pacificmetrics.com','JI');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_action`
--

DROP TABLE IF EXISTS `user_action`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_action` (
  `ua_id` int(11) NOT NULL AUTO_INCREMENT,
  `ua_type` int(11) NOT NULL,
  `u_id` int(10) unsigned NOT NULL,
  `ua_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ua_id`),
  KEY `user_action_ua_type` (`ua_type`),
  KEY `user_action_u_id` (`u_id`),
  CONSTRAINT `user_action_fk_u_id` FOREIGN KEY (`u_id`) REFERENCES `user` (`u_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_action`
--

LOCK TABLES `user_action` WRITE;
/*!40000 ALTER TABLE `user_action` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_action` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_action_item`
--

DROP TABLE IF EXISTS `user_action_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_action_item` (
  `uai_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `i_id` int(11) NOT NULL,
  `u_id` int(10) unsigned NOT NULL,
  `uai_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `uai_process` varchar(255) NOT NULL,
  `uai_detail` varchar(255) NOT NULL,
  PRIMARY KEY (`uai_id`),
  KEY `user_action_item_fk_u_id` (`u_id`),
  KEY `uai_timestamp` (`uai_timestamp`),
  CONSTRAINT `user_action_item_fk_u_id` FOREIGN KEY (`u_id`) REFERENCES `user` (`u_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_action_item`
--

LOCK TABLES `user_action_item` WRITE;
/*!40000 ALTER TABLE `user_action_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_action_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_action_passage`
--

DROP TABLE IF EXISTS `user_action_passage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_action_passage` (
  `uap_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `p_id` int(10) unsigned NOT NULL,
  `u_id` int(10) unsigned NOT NULL,
  `uap_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `uap_process` varchar(255) DEFAULT NULL,
  `uap_detail` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`uap_id`),
  KEY `u_id` (`u_id`),
  KEY `uap_timestamp` (`uap_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_action_passage`
--

LOCK TABLES `user_action_passage` WRITE;
/*!40000 ALTER TABLE `user_action_passage` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_action_passage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_oob_auth`
--

DROP TABLE IF EXISTS `user_oob_auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_oob_auth` (
  `oob_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `oob_valid` tinyint(1) DEFAULT '0',
  `oob_expires` datetime NOT NULL,
  `oob_updated` datetime DEFAULT NULL,
  `oob_type` varchar(45) NOT NULL DEFAULT 'EMAIL',
  `oob_u_id` int(10) NOT NULL,
  `oob_key` varchar(256) NOT NULL,
  PRIMARY KEY (`oob_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_oob_auth`
--

LOCK TABLES `user_oob_auth` WRITE;
/*!40000 ALTER TABLE `user_oob_auth` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_oob_auth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_permission`
--

DROP TABLE IF EXISTS `user_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_permission` (
  `u_id` int(10) unsigned NOT NULL,
  `up_type` int(11) NOT NULL DEFAULT '0',
  `up_value` int(11) NOT NULL DEFAULT '0',
  KEY `u_id` (`u_id`),
  KEY `up_type` (`up_type`),
  KEY `up_value` (`up_value`),
  CONSTRAINT `user_permission_fk_u_id` FOREIGN KEY (`u_id`) REFERENCES `user` (`u_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_permission`
--

LOCK TABLES `user_permission` WRITE;
/*!40000 ALTER TABLE `user_permission` DISABLE KEYS */;
INSERT INTO `user_permission` VALUES (1,1,15);
/*!40000 ALTER TABLE `user_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_supplemental_info`
--

DROP TABLE IF EXISTS `work_supplemental_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `work_supplemental_info` (
  `wsi_id` int(11) NOT NULL AUTO_INCREMENT,
  `ib_id` int(11) NOT NULL,
  `wsi_object_type` tinyint(4) NOT NULL,
  `wsi_object_id` int(11) NOT NULL,
  `wsi_work_type` tinyint(4) NOT NULL,
  `wsi_u_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`wsi_id`),
  KEY `ib_id` (`ib_id`),
  KEY `wsi_object_type` (`wsi_object_type`),
  KEY `wsi_object_id` (`wsi_object_id`),
  KEY `wsi_work_type` (`wsi_work_type`),
  KEY `wsi_u_id` (`wsi_u_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_supplemental_info`
--

LOCK TABLES `work_supplemental_info` WRITE;
/*!40000 ALTER TABLE `work_supplemental_info` DISABLE KEYS */;
/*!40000 ALTER TABLE `work_supplemental_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_supplemental_info_part`
--

DROP TABLE IF EXISTS `work_supplemental_info_part`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `work_supplemental_info_part` (
  `wsip_id` int(11) NOT NULL AUTO_INCREMENT,
  `wsi_id` int(11) NOT NULL,
  PRIMARY KEY (`wsip_id`),
  KEY `wsi_id` (`wsi_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_supplemental_info_part`
--

LOCK TABLES `work_supplemental_info_part` WRITE;
/*!40000 ALTER TABLE `work_supplemental_info_part` DISABLE KEYS */;
/*!40000 ALTER TABLE `work_supplemental_info_part` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `workgroup`
--

DROP TABLE IF EXISTS `workgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `workgroup` (
  `w_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `w_name` varchar(50) NOT NULL,
  `ib_id` int(10) unsigned NOT NULL,
  `w_description` varchar(100) NOT NULL,
  PRIMARY KEY (`w_id`),
  KEY `ib_id` (`ib_id`),
  CONSTRAINT `workgroup_fk_ib_id` FOREIGN KEY (`ib_id`) REFERENCES `item_bank` (`ib_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workgroup`
--

LOCK TABLES `workgroup` WRITE;
/*!40000 ALTER TABLE `workgroup` DISABLE KEYS */;
/*!40000 ALTER TABLE `workgroup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `workgroup_filter`
--

DROP TABLE IF EXISTS `workgroup_filter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `workgroup_filter` (
  `wf_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `w_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`wf_id`),
  KEY `w_id` (`w_id`),
  CONSTRAINT `workgroup_filter_fk_w_id` FOREIGN KEY (`w_id`) REFERENCES `workgroup` (`w_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workgroup_filter`
--

LOCK TABLES `workgroup_filter` WRITE;
/*!40000 ALTER TABLE `workgroup_filter` DISABLE KEYS */;
/*!40000 ALTER TABLE `workgroup_filter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `workgroup_filter_part`
--

DROP TABLE IF EXISTS `workgroup_filter_part`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `workgroup_filter_part` (
  `wfp_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `wf_id` int(10) unsigned NOT NULL,
  `wf_type` int(10) unsigned NOT NULL,
  `wf_value` int(10) unsigned NOT NULL,
  PRIMARY KEY (`wfp_id`),
  KEY `wf_id` (`wf_id`),
  CONSTRAINT `workgroup_filter_part_fk_wf_id` FOREIGN KEY (`wf_id`) REFERENCES `workgroup_filter` (`wf_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workgroup_filter_part`
--

LOCK TABLES `workgroup_filter_part` WRITE;
/*!40000 ALTER TABLE `workgroup_filter_part` DISABLE KEYS */;
/*!40000 ALTER TABLE `workgroup_filter_part` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'cdesbac'
--
/*!50003 DROP FUNCTION IF EXISTS `check_hierarchy_definition` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `check_hierarchy_definition`(check_hd_id INT, hd_id_1 INT, hd_id_2 INT, hd_id_3 INT, hd_id_4 INT, hd_id_5 INT) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
    IF (hd_id_5 IS NOT NULL) THEN 
        RETURN check_one_hierarchy_definition(check_hd_id, hd_id_5);
    END IF;
    IF (hd_id_4 IS NOT NULL) THEN 
        RETURN check_one_hierarchy_definition(check_hd_id, hd_id_4);
    END IF;
    IF (hd_id_3 IS NOT NULL) THEN 
        RETURN check_one_hierarchy_definition(check_hd_id, hd_id_3);
    END IF;
    IF (hd_id_2 IS NOT NULL) THEN 
        RETURN check_one_hierarchy_definition(check_hd_id, hd_id_2);
    END IF;
    IF (hd_id_1 IS NOT NULL) THEN 
        RETURN check_one_hierarchy_definition(check_hd_id, hd_id_1);
    END IF;
    
    RETURN TRUE;
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `check_one_hierarchy_definition` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `check_one_hierarchy_definition`(check_hd_id INT, p_hd_id INT) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
    RETURN check_hd_id IN
        (SELECT hd_id FROM hierarchy_definition 
        WHERE CONCAT(',', hd_parent_path, ',') LIKE CONCAT('%,', p_hd_id, ',%') OR hd_id = p_hd_id);
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `get_most_recent_administration_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `get_most_recent_administration_id`(item_id INT) RETURNS int(11)
    READS SQL DATA
BEGIN
    RETURN 
        (SELECT sa.sa_id FROM stat_administration sa, stat_item_value siv
        WHERE sa.sa_id = siv.sa_id AND siv.i_id = item_id
        ORDER BY sa.sa_timestamp DESC 
        LIMIT 1);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `grade_level_as_str` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `grade_level_as_str`(grade INT) RETURNS char(3) CHARSET latin1
    NO SQL
    DETERMINISTIC
BEGIN
    IF (grade = -1) THEN RETURN 'n/a'; END IF;
    IF (grade = 0) THEN RETURN 'K'; END IF;
    IF (grade = 13) THEN RETURN 'HS'; END IF;
    RETURN CONVERT(grade, CHAR(3));
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `has_outdated_metafiles` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `has_outdated_metafiles`(item_id INT) RETURNS char(1) CHARSET latin1
    READS SQL DATA
BEGIN
    SET @cnt = 
        (SELECT COUNT(*) FROM
        (SELECT ima.*, (SELECT max(ibm_version) FROM item_bank_metafiles ibm WHERE ibm.ibm_id = ima.ibm_id) latest_version
        FROM item_metafile_association ima
        WHERE i_id = item_id) table1
        WHERE table1.latest_version > table1.ibm_version);
    RETURN IF(@cnt > 0, 'Y', 'N');
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `metafiles_count` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `metafiles_count`(item_id INT) RETURNS int(11)
    READS SQL DATA
BEGIN
    SET @cnt = (SELECT COUNT(*) FROM item_metafile_association WHERE i_id = item_id);
    RETURN @cnt;
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `passage_has_outdated_metafiles` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `passage_has_outdated_metafiles`(passage_id INT) RETURNS char(1) CHARSET latin1
    READS SQL DATA
BEGIN
    SET @cnt = 
        (SELECT COUNT(*) FROM
        (SELECT pma.*, (SELECT max(ibm_version) FROM item_bank_metafiles ibm WHERE ibm.ibm_id = pma.ibm_id) latest_version
        FROM passage_metafile_association pma
        WHERE p_id = passage_id) table1
        WHERE table1.latest_version > table1.ibm_version);
    RETURN IF(@cnt > 0, 'Y', 'N');
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `passage_metafiles_count` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `passage_metafiles_count`(passage_id INT) RETURNS int(11)
    READS SQL DATA
BEGIN
    SET @cnt = (SELECT COUNT(*) FROM passage_metafile_association WHERE p_id = passage_id);
    RETURN @cnt;
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `pattern` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 FUNCTION `pattern`(str VARCHAR(100)) RETURNS varchar(100) CHARSET latin1
    NO SQL
BEGIN
    RETURN CONCAT('%', REPLACE(str, '%', '\%'), '%');
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `table_modified` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 DEFINER=`pacific`@`localhost`*/ /*!50003 PROCEDURE `table_modified`(in table_name VARCHAR(50))
    MODIFIES SQL DATA
BEGIN
    UPDATE last_modification SET lm_timestamp = current_timestamp WHERE lm_table_name = table_name; 
    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `characterization_for_item_view`
--

/*!50001 DROP TABLE IF EXISTS `characterization_for_item_view`*/;
/*!50001 DROP VIEW IF EXISTS `characterization_for_item_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `characterization_for_item_view` AS select `i`.`i_id` AS `i_id`,`i1`.`ic_value` AS `item_standard`,`i2`.`ic_value` AS `content_area`,`i3`.`ic_value` AS `grade_level`,`i5`.`ic_value` AS `grade_span_start`,`i6`.`ic_value` AS `grade_span_end`,`i7`.`ic_value` AS `points`,`i8`.`ic_value` AS `depth_of_knowledge` from (((((((`item` `i` left join `item_characterization` `i1` on(((`i`.`i_id` = `i1`.`i_id`) and (`i1`.`ic_type` = 1)))) left join `item_characterization` `i2` on(((`i`.`i_id` = `i2`.`i_id`) and (`i2`.`ic_type` = 2)))) left join `item_characterization` `i3` on(((`i`.`i_id` = `i3`.`i_id`) and (`i3`.`ic_type` = 3)))) left join `item_characterization` `i5` on(((`i`.`i_id` = `i5`.`i_id`) and (`i5`.`ic_type` = 5)))) left join `item_characterization` `i6` on(((`i`.`i_id` = `i6`.`i_id`) and (`i6`.`ic_type` = 6)))) left join `item_characterization` `i7` on(((`i`.`i_id` = `i7`.`i_id`) and (`i7`.`ic_type` = 7)))) left join `item_characterization` `i8` on(((`i`.`i_id` = `i8`.`i_id`) and (`i8`.`ic_type` = 8)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `characterization_for_passage_view`
--

/*!50001 DROP TABLE IF EXISTS `characterization_for_passage_view`*/;
/*!50001 DROP VIEW IF EXISTS `characterization_for_passage_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `characterization_for_passage_view` AS select `p`.`p_id` AS `p_id`,`p2`.`oc_int_value` AS `content_area`,`p3`.`oc_int_value` AS `grade_level`,`p5`.`oc_int_value` AS `grade_span_start`,`p6`.`oc_int_value` AS `grade_span_end` from ((((`passage` `p` left join `object_characterization` `p2` on(((`p`.`p_id` = `p2`.`oc_object_id`) and (`p2`.`oc_characteristic` = 2)))) left join `object_characterization` `p3` on(((`p`.`p_id` = `p3`.`oc_object_id`) and (`p3`.`oc_characteristic` = 3)))) left join `object_characterization` `p5` on(((`p`.`p_id` = `p5`.`oc_object_id`) and (`p5`.`oc_characteristic` = 5)))) left join `object_characterization` `p6` on(((`p`.`p_id` = `p6`.`oc_object_id`) and (`p6`.`oc_characteristic` = 6)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `hierarchy_definition_1_view`
--

/*!50001 DROP TABLE IF EXISTS `hierarchy_definition_1_view`*/;
/*!50001 DROP VIEW IF EXISTS `hierarchy_definition_1_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `hierarchy_definition_1_view` AS select `hierarchy_definition`.`hd_id` AS `hd_id`,`hierarchy_definition`.`hd_type` AS `hd_type`,`hierarchy_definition`.`hd_value` AS `hd_value`,`hierarchy_definition`.`hd_parent_id` AS `hd_parent_id`,`hierarchy_definition`.`hd_posn_in_parent` AS `hd_posn_in_parent`,`hierarchy_definition`.`hd_std_desc` AS `hd_std_desc`,`hierarchy_definition`.`hd_extended_desc` AS `hd_extended_desc`,`hierarchy_definition`.`hd_parent_path` AS `hd_parent_path` from `hierarchy_definition` where `hierarchy_definition`.`hd_parent_id` in (select `hierarchy_definition`.`hd_id` AS `hd_id` from `hierarchy_definition` where (`hierarchy_definition`.`hd_parent_id` = 0)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `item_report_view`
--

/*!50001 DROP TABLE IF EXISTS `item_report_view`*/;
/*!50001 DROP VIEW IF EXISTS `item_report_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `item_report_view` AS select `item`.`ib_id` AS `ItemBankId`,`item_bank`.`ib_external_id` AS `ItemBankExternalId`,`item`.`i_external_id` AS `ItemExternalId`,`ic_content_area`.`ic_value` AS `ContentAreaId`,ifnull(`content_area`.`ca_name`,_latin1'') AS `ContentAreaName`,ifnull(`grade_level_as_str`(`ic_grade_level`.`ic_value`),_latin1'') AS `GradeLevel`,ifnull(`grade_level_as_str`(`ic_grade_from`.`ic_value`),_latin1'') AS `GradeFrom`,ifnull(`grade_level_as_str`(`ic_grade_to`.`ic_value`),_latin1'') AS `GradeTo`,if(((`ic_grade_from`.`ic_value` >= 0) or (`ic_grade_to`.`ic_value` >= 0)),ifnull(concat(`grade_level_as_str`(`ic_grade_from`.`ic_value`),_latin1' - ',`grade_level_as_str`(`ic_grade_to`.`ic_value`)),_latin1''),_latin1'') AS `GradeSpan`,ifnull(`item_format`.`itf_name`,_latin1'') AS `ItemFormatName`,ifnull(`dev_state`.`ds_name`,_latin1'') AS `DevStateName`,ifnull(`difficulty`.`d_name`,_latin1'') AS `DifficultyName`,ifnull(`publication_status`.`ps_name`,_latin1'') AS `PublicationStatusName`,ifnull(`user`.`u_username`,_latin1'') AS `ItemWriter`,ifnull(`item`.`i_readability_index`,_latin1'') AS `ReadabilityIndex`,ifnull(`item`.`i_description`,_latin1'') AS `ItemDescription` from (((((((((((`item` join `item_bank` on((`item`.`ib_id` = `item_bank`.`ib_id`))) left join `item_characterization` `ic_content_area` on(((`item`.`i_id` = `ic_content_area`.`i_id`) and (`ic_content_area`.`ic_type` = 2)))) left join `content_area` on((`ic_content_area`.`ic_value` = `content_area`.`ca_id`))) left join `item_characterization` `ic_grade_level` on(((`item`.`i_id` = `ic_grade_level`.`i_id`) and (`ic_grade_level`.`ic_type` = 3)))) left join `item_characterization` `ic_grade_from` on(((`item`.`i_id` = `ic_grade_from`.`i_id`) and (`ic_grade_from`.`ic_type` = 5)))) left join `item_characterization` `ic_grade_to` on(((`item`.`i_id` = `ic_grade_to`.`i_id`) and (`ic_grade_to`.`ic_type` = 6)))) left join `item_format` on((`item`.`i_format` = `item_format`.`itf_id`))) left join `dev_state` on((`item`.`i_dev_state` = `dev_state`.`ds_id`))) left join `difficulty` on((`item`.`i_difficulty` = `difficulty`.`d_id`))) left join `publication_status` on((`item`.`i_publication_status` = `publication_status`.`ps_id`))) left join `user` on((`user`.`u_id` = `item`.`i_author`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `single_item_view`
--

/*!50001 DROP TABLE IF EXISTS `single_item_view`*/;
/*!50001 DROP VIEW IF EXISTS `single_item_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `single_item_view` AS select `i`.`i_id` AS `i_id`,`i`.`i_external_id` AS `i_external_id`,`i`.`i_description` AS `i_description`,`ib`.`ib_external_id` AS `item_bank`,`cfi`.`points` AS `points`,`cfi`.`grade_level` AS `grade_level`,`cfi`.`grade_span_start` AS `grade_span_start`,`cfi`.`grade_span_end` AS `grade_span_end`,`ca`.`ca_name` AS `content_area`,`it`.`it_name` AS `item_type`,`ps`.`ps_name` AS `publication_status` from (((((`item` `i` join `characterization_for_item_view` `cfi` on((`i`.`i_id` = `cfi`.`i_id`))) join `item_bank` `ib` on((`i`.`ib_id` = `ib`.`ib_id`))) join `content_area` `ca` on((`cfi`.`content_area` = `ca`.`ca_id`))) join `item_type` `it` on((`i`.`i_type` = `it`.`it_id`))) join `publication_status` `ps` on((`i`.`i_publication_status` = `ps`.`ps_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `single_item_view_with_content`
--

/*!50001 DROP TABLE IF EXISTS `single_item_view_with_content`*/;
/*!50001 DROP VIEW IF EXISTS `single_item_view_with_content`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `single_item_view_with_content` AS select `siv`.`i_id` AS `i_id`,`siv`.`i_external_id` AS `i_external_id`,`siv`.`i_description` AS `i_description`,`siv`.`item_bank` AS `item_bank`,`siv`.`points` AS `points`,`siv`.`grade_level` AS `grade_level`,`siv`.`content_area` AS `content_area`,`siv`.`item_type` AS `item_type`,`siv`.`publication_status` AS `publication_status`,group_concat(`ifr`.`if_text` separator '<br>') AS `i_html` from (`single_item_view` `siv` join `item_fragment` `ifr`) where ((`siv`.`i_id` = `ifr`.`i_id`) and (`ifr`.`if_type` in (1,2))) group by `siv`.`i_id` order by `ifr`.`if_type` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `stat_admin_item_value_view`
--

/*!50001 DROP TABLE IF EXISTS `stat_admin_item_value_view`*/;
/*!50001 DROP VIEW IF EXISTS `stat_admin_item_value_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `stat_admin_item_value_view` AS select `sai`.`i_id` AS `i_id`,`sai`.`sa_id` AS `sa_id`,`siv1`.`siv_numeric_value` AS `value1`,`siv2`.`siv_numeric_value` AS `value2`,`siv3`.`siv_numeric_value` AS `value3`,`siv4`.`siv_numeric_value` AS `value4`,`siv5`.`siv_numeric_value` AS `value5`,`siv6`.`siv_numeric_value` AS `value6`,`siv7`.`siv_numeric_value` AS `value7`,`siv8`.`siv_numeric_value` AS `value8`,`siv9`.`siv_numeric_value` AS `value9`,`siv10`.`siv_numeric_value` AS `value10` from ((((((((((`stat_administration_item_view` `sai` left join `stat_item_value` `siv1` on(((`siv1`.`sk_id` = 1) and (`siv1`.`i_id` = `sai`.`i_id`) and (`siv1`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv2` on(((`siv2`.`sk_id` = 2) and (`siv2`.`i_id` = `sai`.`i_id`) and (`siv2`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv3` on(((`siv3`.`sk_id` = 3) and (`siv3`.`i_id` = `sai`.`i_id`) and (`siv3`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv4` on(((`siv4`.`sk_id` = 4) and (`siv4`.`i_id` = `sai`.`i_id`) and (`siv4`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv5` on(((`siv5`.`sk_id` = 5) and (`siv5`.`i_id` = `sai`.`i_id`) and (`siv5`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv6` on(((`siv6`.`sk_id` = 6) and (`siv6`.`i_id` = `sai`.`i_id`) and (`siv6`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv7` on(((`siv7`.`sk_id` = 7) and (`siv7`.`i_id` = `sai`.`i_id`) and (`siv7`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv8` on(((`siv8`.`sk_id` = 8) and (`siv8`.`i_id` = `sai`.`i_id`) and (`siv8`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv9` on(((`siv9`.`sk_id` = 9) and (`siv9`.`i_id` = `sai`.`i_id`) and (`siv9`.`sa_id` = `sai`.`sa_id`)))) left join `stat_item_value` `siv10` on(((`siv10`.`sk_id` = 10) and (`siv10`.`i_id` = `sai`.`i_id`) and (`siv10`.`sa_id` = `sai`.`sa_id`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `stat_administration_item_view`
--

/*!50001 DROP TABLE IF EXISTS `stat_administration_item_view`*/;
/*!50001 DROP VIEW IF EXISTS `stat_administration_item_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `stat_administration_item_view` AS select distinct `siv`.`sa_id` AS `sa_id`,`siv`.`i_id` AS `i_id` from ((`item` `i` join `stat_item_value` `siv` on((`i`.`i_id` = `siv`.`i_id`))) join `stat_administration` `sa` on((`siv`.`sa_id` = `sa`.`sa_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `stat_key_name_view`
--

/*!50001 DROP TABLE IF EXISTS `stat_key_name_view`*/;
/*!50001 DROP VIEW IF EXISTS `stat_key_name_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`pacific`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `stat_key_name_view` AS select `sk1`.`sk_name` AS `name1`,`sk2`.`sk_name` AS `name2`,`sk3`.`sk_name` AS `name3`,`sk4`.`sk_name` AS `name4`,`sk5`.`sk_name` AS `name5`,`sk6`.`sk_name` AS `name6`,`sk7`.`sk_name` AS `name7`,`sk8`.`sk_name` AS `name8`,`sk9`.`sk_name` AS `name9`,`sk10`.`sk_name` AS `name10` from (((((((((`stat_key` `sk1` join `stat_key` `sk2`) join `stat_key` `sk3`) join `stat_key` `sk4`) join `stat_key` `sk5`) join `stat_key` `sk6`) join `stat_key` `sk7`) join `stat_key` `sk8`) join `stat_key` `sk9`) join `stat_key` `sk10`) where ((`sk1`.`sk_id` = 1) and (`sk2`.`sk_id` = 2) and (`sk3`.`sk_id` = 3) and (`sk4`.`sk_id` = 4) and (`sk5`.`sk_id` = 5) and (`sk6`.`sk_id` = 6) and (`sk7`.`sk_id` = 7) and (`sk8`.`sk_id` = 8) and (`sk9`.`sk_id` = 9) and (`sk10`.`sk_id` = 10)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-04-24 13:45:33
