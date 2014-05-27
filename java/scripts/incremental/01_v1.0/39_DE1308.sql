DELETE FROM publication_status;
ALTER TABLE publication_status MODIFY COLUMN ps_name varchar(100) NOT NULL;
INSERT INTO publication_status SET ps_id=0, ps_name='Unused';
INSERT INTO publication_status SET ps_id=1, ps_name='Field Test';
INSERT INTO publication_status SET ps_id=2, ps_name='Embedded Field Test';
INSERT INTO publication_status SET ps_id=3, ps_name='Operational';
INSERT INTO publication_status SET ps_id=4, ps_name='Field Tested';
INSERT INTO publication_status SET ps_id=5, ps_name='Pilot';
INSERT INTO publication_status SET ps_id=6, ps_name='Equating';
INSERT INTO publication_status SET ps_id=7, ps_name='Released';
INSERT INTO publication_status SET ps_id=8, ps_name='Ready for Operational';
INSERT INTO publication_status SET ps_id=9, ps_name='Ready for Field Test';
INSERT INTO publication_status SET ps_id=10, ps_name='Ready for Pilot Test';
INSERT INTO publication_status SET ps_id=11, ps_name='Pilot Tested';
INSERT INTO publication_status SET ps_id=12, ps_name='Ready for Field Review';
INSERT INTO publication_status SET ps_id=13, ps_name='Field Reviewed';
INSERT INTO publication_status SET ps_id=14, ps_name='Operational Equating';
INSERT INTO publication_status SET ps_id=15, ps_name='Rejected';

