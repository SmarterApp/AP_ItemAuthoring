-- Comments from the original DB2 Quartz file:
--
-- Updated by Claudiu Crisan (claudiu.crisan@schartner.net)
-- SQL scripts for DB2 ver 8.1
--
-- Changes:
-- - "varchar(1)" replaced with "integer"
-- - "field_name varchar(xxx) not null" replaced with "field_name varchar(xxx)"
--
--
-- Comments from Jaspersoft:
--
-- DB2 Version Notes:
--
--   - This script is intended to be used with DB2 version 8.x
--
--
-- 2012-05-23: tkavanagh:
--             In the switch from quartz 1.5 to 2.1.2, we have to handle the
--             table and column size changes carefully because of existing
--             JRS customers who will be upgrading from older JRS (and thus
--             older quartz). If column sizes were made larger in quartz
--             2.1.2, we are ignoring this and leaving the col size the same.
--             So, for instance, if qrtz_job_details.JOB_NAME was increased
--             to (200) in 2.1.2, I explicitly set it to (80) which is what it
--             was in quartz 1.5. JRS 4.7.0 upgraded to quartz 2.1.2.




-- DROP TABLE QRTZ_FIRED_TRIGGERS;
-- DROP TABLE QRTZ_PAUSED_TRIGGER_GRPS;
-- DROP TABLE QRTZ_SCHEDULER_STATE;
-- DROP TABLE QRTZ_LOCKS;
-- DROP TABLE QRTZ_SIMPLE_TRIGGERS;
-- DROP TABLE QRTZ_SIMPROP_TRIGGERS;
-- DROP TABLE QRTZ_CRON_TRIGGERS;
-- DROP TABLE QRTZ_TRIGGERS;
-- DROP TABLE QRTZ_JOB_DETAILS;
-- DROP TABLE QRTZ_CALENDARS;
-- DROP TABLE QRTZ_BLOB_TRIGGERS;

CREATE TABLE qrtz_job_details(
sched_name varchar(100) not null,
job_name varchar(80) not null,
job_group varchar(80) not null,
description varchar(120),
job_class_name varchar(128) not null,
is_durable integer not null,
is_nonconcurrent integer not null,
is_update_data integer not null,
requests_recovery integer not null,
job_data blob(2000),
PRIMARY KEY (sched_name,job_name,job_group)
);

CREATE TABLE qrtz_triggers(
sched_name varchar(100) not null,
trigger_name varchar(80) not null,
trigger_group varchar(80) not null,
job_name varchar(80) not null,
job_group varchar(80) not null,
description varchar(120),
next_fire_time bigint,
prev_fire_time bigint,
priority integer,
trigger_state varchar(16) not null,
trigger_type varchar(8) not null,
start_time bigint not null,
end_time bigint,
calendar_name varchar(80),
misfire_instr smallint,
job_data blob(2000),
PRIMARY KEY (sched_name,trigger_name,trigger_group),
FOREIGN KEY (sched_name,job_name,job_group) REFERENCES qrtz_job_details(sched_name,job_name,job_group)
);

CREATE TABLE qrtz_simple_triggers(
sched_name varchar(100) not null,
trigger_name varchar(80) not null,
trigger_group varchar(80) not null,
repeat_count bigint not null,
repeat_interval bigint not null,
times_triggered bigint not null,
PRIMARY KEY (sched_name,trigger_name,trigger_group),
FOREIGN KEY (sched_name,trigger_name,trigger_group) REFERENCES qrtz_triggers(sched_name,trigger_name,trigger_group)
);

CREATE TABLE qrtz_cron_triggers(
sched_name varchar(100) not null,
trigger_name varchar(80) not null,
trigger_group varchar(80) not null,
cron_expression varchar(80) not null,
time_zone_id varchar(80),
PRIMARY KEY (sched_name,trigger_name,trigger_group),
FOREIGN KEY (sched_name,trigger_name,trigger_group) REFERENCES qrtz_triggers(sched_name,trigger_name,trigger_group)
);

------------------------------------------------------------------------
-- 2012-03-29: thorick chow:
--             This CREATE TABLE statement is failing on DB2 V8.2 for Windows
--             Apparently, we can't have the NULL declarations on the columns
--
--CREATE TABLE qrtz_simprop_triggers
--  (
--    sched_name varchar(120) not null,
--    TRIGGER_NAME VARCHAR(200) NOT NULL,
--    TRIGGER_GROUP VARCHAR(200) NOT NULL,
--    STR_PROP_1 VARCHAR(512) NULL,
--    STR_PROP_2 VARCHAR(512) NULL,
--    STR_PROP_3 VARCHAR(512) NULL,
--    INT_PROP_1 INT NULL,
--    INT_PROP_2 INT NULL,
--    LONG_PROP_1 BIGINT NULL,
--    LONG_PROP_2 BIGINT NULL,
--    DEC_PROP_1 NUMERIC(13,4) NULL,
--    DEC_PROP_2 NUMERIC(13,4) NULL,
--    BOOL_PROP_1 VARCHAR(1) NULL,
--    BOOL_PROP_2 VARCHAR(1) NULL,
--    PRIMARY KEY (sched_name,TRIGGER_NAME,TRIGGER_GROUP),
--    FOREIGN KEY (sched_name,TRIGGER_NAME,TRIGGER_GROUP)
--    REFERENCES QRTZ_TRIGGERS(sched_name,TRIGGER_NAME,TRIGGER_GROUP)
--);
--------------------------------------------------------------------------


CREATE TABLE qrtz_simprop_triggers
  (
    sched_name varchar(100) not null,
    TRIGGER_NAME VARCHAR(80) NOT NULL,
    TRIGGER_GROUP VARCHAR(80) NOT NULL,
    STR_PROP_1 VARCHAR(512),
    STR_PROP_2 VARCHAR(512),
    STR_PROP_3 VARCHAR(512),
    INT_PROP_1 INT,
    INT_PROP_2 INT,
    LONG_PROP_1 BIGINT,
    LONG_PROP_2 BIGINT,
    DEC_PROP_1 NUMERIC(13,4),
    DEC_PROP_2 NUMERIC(13,4),
    BOOL_PROP_1 VARCHAR(1),
    BOOL_PROP_2 VARCHAR(1),
    PRIMARY KEY (sched_name,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (sched_name,TRIGGER_NAME,TRIGGER_GROUP)
    REFERENCES QRTZ_TRIGGERS(sched_name,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE qrtz_blob_triggers(
sched_name varchar(100) not null,
trigger_name varchar(80) not null,
trigger_group varchar(80) not null,
blob_data blob(2000),
PRIMARY KEY (sched_name,trigger_name,trigger_group),
FOREIGN KEY (sched_name,trigger_name,trigger_group) REFERENCES qrtz_triggers(sched_name,trigger_name,trigger_group)
);

CREATE TABLE qrtz_calendars(
sched_name varchar(100) not null,
calendar_name varchar(80) not null,
calendar blob(4000) not null,
PRIMARY KEY (sched_name,calendar_name)
);

CREATE TABLE qrtz_fired_triggers(
sched_name varchar(100) not null,
entry_id varchar(95) not null,
trigger_name varchar(80) not null,
trigger_group varchar(80) not null,
instance_name varchar(80) not null,
fired_time bigint not null,
priority integer not null,
state varchar(16) not null,
job_name varchar(80),
job_group varchar(80),
is_nonconcurrent integer,
requests_recovery integer,
PRIMARY KEY (sched_name,entry_id)
);

CREATE TABLE qrtz_paused_trigger_grps(
sched_name varchar(100) not null,
trigger_group varchar(80) not null,
PRIMARY KEY (sched_name,trigger_group)
);

CREATE TABLE qrtz_scheduler_state(
sched_name varchar(100) not null,
instance_name varchar(80) not null,
last_checkin_time bigint not null,
checkin_interval bigint not null,
PRIMARY KEY (sched_name,instance_name)
);

CREATE TABLE qrtz_locks(
sched_name varchar(100) not null,
lock_name varchar(40) not null,
PRIMARY KEY (sched_name,lock_name)
);
