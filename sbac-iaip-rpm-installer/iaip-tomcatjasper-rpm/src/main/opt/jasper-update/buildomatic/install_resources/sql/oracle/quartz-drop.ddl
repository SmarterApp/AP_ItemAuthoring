--
-- 2012-01-24  thorick chow:  separate quartz drop script for oracle
--

DELETE FROM qrtz_fired_triggers;
DELETE FROM qrtz_simple_triggers;
DELETE FROM qrtz_simprop_triggers;
DELETE FROM qrtz_cron_triggers;
DELETE FROM qrtz_blob_triggers;
DELETE FROM qrtz_triggers;
DELETE FROM qrtz_job_details;
DELETE FROM qrtz_calendars;
DELETE FROM qrtz_paused_trigger_grps;
DELETE FROM qrtz_locks;
DELETE FROM qrtz_scheduler_state;

DROP TABLE qrtz_calendars;
DROP TABLE qrtz_fired_triggers;
DROP TABLE qrtz_blob_triggers;
DROP TABLE qrtz_cron_triggers;
DROP TABLE qrtz_simple_triggers;
DROP TABLE qrtz_simprop_triggers;
DROP TABLE qrtz_triggers;
DROP TABLE qrtz_job_details;
DROP TABLE qrtz_paused_trigger_grps;
DROP TABLE qrtz_locks;
DROP TABLE qrtz_scheduler_state;

