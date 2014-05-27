/* DE1300: make sure item_bank.o_id field is set */
UPDATE item_bank SET o_id=1 WHERE o_id=0;
