INSERT INTO `organization` VALUES (1,'SBAC','Consortium-level organization');
INSERT INTO `item_bank` VALUES (15,1,8,'SBAC_Demo_Program','Demo program for SBAC testing purposes','SBAC','0000-00-00','http://cde.pacificmetrics.com/devcdesbac/gui/item.',0,0,18,124058);
INSERT INTO `user_permission` VALUES (1,1,15);

SET @itembank = (SELECT ib_id FROM item_bank WHERE ib_external_id LIKE "SBAC%");
SET @username = (SELECT CAST(CONCAT(DATABASE(), @itembank)AS CHAR));
-- emptyp@ssw0rd
INSERT INTO user SET u_username=@username, u_password='$apr1$QRg/eZZa$pmNNjD3E/ARpgh7nT.LHR1', u_type=11, u_active=1, u_deleted=0, u_admin_type=0, u_review_type=0, u_permissions=0, o_id=1, u_first_name='Item', u_last_name='Importer', u_email='cde@pacificmetrics.com';
UPDATE item_bank SET ib_importer_u_id=(SELECT u_id FROM user WHERE u_username=@username) WHERE ib_id=@itembank;