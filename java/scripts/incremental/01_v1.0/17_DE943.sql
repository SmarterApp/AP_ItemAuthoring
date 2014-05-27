-- Add new column 'ib_id' to 'item_status' table 
ALTER TABLE item_status ADD COLUMN ib_id  INT(10) NOT NULL default 0 AFTER i_tei_data;

-- Initialize new column 'item_status.ib_id' with item's current 'ib_id' value
UPDATE item_status, item SET item_status.ib_id = item.ib_id WHERE item_status.i_id = item.i_id;
