SET @MAX_ID = (select max(dst_id) + 1 from cdesbac.detail_status_type);
insert into cdesbac.detail_status_type values(@MAX_ID,7,'success','Item exported successfully to Test Item Bank');  
SET @MAX_ID = (select max(dst_id) + 1 from cdesbac.detail_status_type);
insert into cdesbac.detail_status_type values(@MAX_ID,8,'error','Unable to export items to Test Item Bank');  
