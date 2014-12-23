DROP FUNCTION IF EXISTS `get_most_recent_administration_id`;


CREATE FUNCTION `get_most_recent_administration_id`(item_id INT) RETURNS int(11)
    READS SQL DATA
BEGIN
    RETURN 
        (SELECT siv.sa_id 
		FROM stat_item_value siv,
			stat_identifier_admin sia,
			stat_import_identifier sii 
        WHERE siv.i_id = item_id
		AND sia.sa_id = siv.sa_id
		AND sii.sii_id = sia.sii_id
        ORDER BY sii.sii_timestamp DESC 
        LIMIT 1);
  END;
/

