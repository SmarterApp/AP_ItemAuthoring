DELETE FROM item_characterization WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_characterization ADD CONSTRAINT item_characterization_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM item_fragment WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_fragment ADD CONSTRAINT item_fragment_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM item_interaction WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_interaction ADD CONSTRAINT item_interaction_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM item_status WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_status ADD CONSTRAINT item_status_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM item_status_fragment WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_status_fragment ADD CONSTRAINT item_status_fragment_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM item_asset_attribute WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_asset_attribute MODIFY COLUMN i_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE item_asset_attribute ADD CONSTRAINT item_asset_attribute_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM item_comment WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_comment MODIFY COLUMN i_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE item_comment ADD CONSTRAINT item_comment_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM item_alternate WHERE i_id NOT IN (SELECT i_id FROM item);
ALTER TABLE item_alternate MODIFY COLUMN i_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE item_alternate ADD CONSTRAINT item_alternate_fk_i_id FOREIGN KEY (i_id) REFERENCES item(i_id);

DELETE FROM user_permission WHERE u_id NOT IN (SELECT u_id FROM user);
ALTER TABLE user_permission MODIFY COLUMN u_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE user_permission ADD CONSTRAINT user_permission_fk_u_id FOREIGN KEY (u_id) REFERENCES user(u_id);

DELETE FROM user_action WHERE u_id NOT IN (SELECT u_id FROM user);
ALTER TABLE user_action MODIFY COLUMN u_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE user_action ADD CONSTRAINT user_action_fk_u_id FOREIGN KEY (u_id) REFERENCES user(u_id);

DELETE FROM user_action_item WHERE u_id NOT IN (SELECT u_id FROM user);
ALTER TABLE user_action_item MODIFY COLUMN u_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE user_action_item ADD CONSTRAINT user_action_item_fk_u_id FOREIGN KEY (u_id) REFERENCES user(u_id);

DELETE FROM item WHERE ib_id NOT IN (SELECT ib_id FROM item_bank);
ALTER TABLE item MODIFY COLUMN ib_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE item ADD CONSTRAINT item_fk_ib_id FOREIGN KEY (ib_id) REFERENCES item_bank(ib_id);

DELETE FROM passage WHERE ib_id NOT IN (SELECT ib_id FROM item_bank);
ALTER TABLE passage MODIFY COLUMN ib_id INT(10) UNSIGNED NOT NULL;
ALTER TABLE passage ADD CONSTRAINT passage_fk_ib_id FOREIGN KEY (ib_id) REFERENCES item_bank(ib_id);