-- Add new column 'ib_id' to 'passage_status' table 
ALTER TABLE passage_status ADD COLUMN ib_id  INT(10) NOT NULL default 0 AFTER ps_footnotes;

-- Initialize new column 'passage_status.ib_id' with passage's current 'ib_id' value
UPDATE passage_status, passage SET passage_status.ib_id = passage.ib_id WHERE passage_status.p_id = passage.p_id;