DROP FUNCTION IF EXISTS `get_most_recent_administration_id`;

CREATE FUNCTION `get_most_recent_administration_id`(item_id INT) RETURNS int(11)
    READS SQL DATA
BEGIN
    RETURN 
        (SELECT sa.sa_id FROM stat_administration sa, stat_item_value siv
        WHERE sa.sa_id = siv.sa_id AND siv.i_id = item_id
        ORDER BY sa.sa_timestamp DESC 
        LIMIT 1);
END;
/

DROP FUNCTION IF EXISTS `pattern`;

CREATE FUNCTION `pattern`(str VARCHAR(100)) RETURNS VARCHAR(100) CHARSET latin1
    NO SQL
BEGIN
    RETURN CONCAT('%', REPLACE(str, '%', '\%'), '%');
END;
/