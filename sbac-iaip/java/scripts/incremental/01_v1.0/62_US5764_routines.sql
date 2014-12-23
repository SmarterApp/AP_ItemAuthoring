DROP FUNCTION IF EXISTS `get_associated_standards`;

CREATE FUNCTION `get_associated_standards`(item_id INT) RETURNS TEXT
    READS SQL DATA
BEGIN
    DECLARE v_associated_standards TEXT;
	DECLARE v_standard TEXT;
	DECLARE v_finished INT DEFAULT 0;
	
	DEClARE secondary_standard_cursor CURSOR FOR
			SELECT isd_standard FROM item_standard WHERE i_id = item_id;
	DECLARE CONTINUE HANDLER 
			FOR NOT FOUND SET v_finished = 1;

	SET v_associated_standards = '';

	SELECT i_primary_standard INTO v_standard
	FROM item
	WHERE i_id = item_id;

	IF (v_standard IS NOT NULL) THEN
		SET v_associated_standards = v_standard;
	END IF;

	OPEN secondary_standard_cursor;
	 
	get_secondary_standard: LOOP

		FETCH secondary_standard_cursor INTO v_standard;

		IF v_finished = 1 THEN 
			LEAVE get_secondary_standard;
		END IF;

		IF (v_associated_standards = '') THEN
			SET v_associated_standards = v_standard;
		ELSE
			SET v_associated_standards = CONCAT(v_associated_standards, '\n', v_standard);
		END IF;
	END LOOP get_secondary_standard;

	CLOSE secondary_standard_cursor;

    RETURN v_associated_standards;
  END;
/
