CREATE PROCEDURE `table_modified`(in table_name VARCHAR(50))
    MODIFIES SQL DATA
BEGIN
    UPDATE last_modification SET lm_timestamp = current_timestamp WHERE lm_table_name = table_name; 
    END;
/
CREATE FUNCTION `check_one_hierarchy_definition`(check_hd_id INT, p_hd_id INT) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
    RETURN check_hd_id IN
        (SELECT hd_id FROM hierarchy_definition 
        WHERE CONCAT(',', hd_parent_path, ',') LIKE CONCAT('%,', p_hd_id, ',%') OR hd_id = p_hd_id);
    END;
/
CREATE FUNCTION `check_hierarchy_definition`(check_hd_id INT, hd_id_1 INT, hd_id_2 INT, hd_id_3 INT, hd_id_4 INT, hd_id_5 INT) RETURNS tinyint(1)
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
    END;
/
CREATE FUNCTION `grade_level_as_str`(grade INT) RETURNS char(3) CHARSET latin1
    NO SQL
    DETERMINISTIC
BEGIN
    IF (grade = -1) THEN RETURN 'n/a'; END IF;
    IF (grade = 0) THEN RETURN 'K'; END IF;
    IF (grade = 13) THEN RETURN 'HS'; END IF;
    RETURN CONVERT(grade, CHAR(3));
    END;
/
CREATE FUNCTION `has_outdated_metafiles`(item_id INT) RETURNS char(1) CHARSET latin1
    READS SQL DATA
BEGIN
    SET @cnt = 
        (SELECT COUNT(*) FROM
        (SELECT ima.*, (SELECT max(ibm_version) FROM item_bank_metafiles ibm WHERE ibm.ibm_id = ima.ibm_id) latest_version
        FROM item_metafile_association ima
        WHERE i_id = item_id) table1
        WHERE table1.latest_version > table1.ibm_version);
    RETURN IF(@cnt > 0, 'Y', 'N');
    END;
/
CREATE FUNCTION `metafiles_count`(item_id INT) RETURNS int(11)
    READS SQL DATA
BEGIN
    SET @cnt = (SELECT COUNT(*) FROM item_metafile_association WHERE i_id = item_id);
    RETURN @cnt;
    END;
/
CREATE FUNCTION `passage_has_outdated_metafiles`(passage_id INT) RETURNS char(1) CHARSET latin1
    READS SQL DATA
BEGIN
    SET @cnt = 
        (SELECT COUNT(*) FROM
        (SELECT pma.*, (SELECT max(ibm_version) FROM item_bank_metafiles ibm WHERE ibm.ibm_id = pma.ibm_id) latest_version
        FROM passage_metafile_association pma
        WHERE p_id = passage_id) table1
        WHERE table1.latest_version > table1.ibm_version);
    RETURN IF(@cnt > 0, 'Y', 'N');
    END;
/
CREATE FUNCTION `passage_metafiles_count`(passage_id INT) RETURNS int(11)
    READS SQL DATA
BEGIN
    SET @cnt = (SELECT COUNT(*) FROM passage_metafile_association WHERE p_id = passage_id);
    RETURN @cnt;
    END;
/