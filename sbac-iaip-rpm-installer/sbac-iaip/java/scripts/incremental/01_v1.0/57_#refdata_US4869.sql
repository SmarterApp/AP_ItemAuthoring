SET @MAX_ID = (select max(dst_id) + 1 from cdesbac.detail_status_type);
insert into cdesbac.detail_status_type values(@MAX_ID,6,'error','Missing Metadata Element(s)'); 
