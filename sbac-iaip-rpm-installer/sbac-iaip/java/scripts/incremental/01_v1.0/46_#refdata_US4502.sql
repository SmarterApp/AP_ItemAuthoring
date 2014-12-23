insert  into `item_move_type` (`imt_id`,`imt_name`) values (1,'Import');
insert  into `item_move_type` (`imt_id`,`imt_name`) values (2,'Export');

insert  into `item_move_status` (`ims_id`,`ims_value`) values (1,'Complete');
insert  into `item_move_status` (`ims_id`,`ims_value`) values (2,'Incomplete');
insert  into `item_move_status` (`ims_id`,`ims_value`) values (3,'In Progress');

insert  into `detail_status_type` (`dst_id`,`dst_code`,`dst_type`,`dst_value`) values (1,'0','success','');
insert  into `detail_status_type` (`dst_id`,`dst_code`,`dst_type`,`dst_value`) values (2,'5000','error','missing asset');