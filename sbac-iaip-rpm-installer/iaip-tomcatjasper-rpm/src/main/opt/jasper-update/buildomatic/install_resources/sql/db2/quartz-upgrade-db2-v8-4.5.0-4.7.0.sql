--
--  2012-03-22 thorick chow:  adopted for DB2 v8.2
--
--
-- drop tables that are no longer used
-- 
DROP TABLE qrtz_job_listeners;
DROP TABLE qrtz_trigger_listeners;

-- 
--  drop columns that are no longer used
--
---------------------------------------------------------------
--  2012-03-28  thorick chow
--   ALERT !  THERE IS NO DROP COLUMN COMMAND IN DB2 V8
--      FOR NOW, WE'RE JUST RETAINING THE OLD COLUMNS
--        QUARTZ USES DIRECT JDBC TO ACCESS THE TABLES
--        SO THE RETAINED UNUSED COLUMNS MAY NOT MATTER
--        AS LONG AS COLUMN ACCESS IS BY NAME AND NOT POSITION
--
--ALTER TABLE qrtz_job_details DROP COLUMN is_volatile;
--ALTER TABLE qrtz_triggers DROP COLUMN is_volatile;
--ALTER TABLE qrtz_fired_triggers DROP COLUMN is_volatile;
--
----------------------------------------------------------------


-- 
--  add new columns and columns that replace 'is_stateful'
--
ALTER TABLE qrtz_job_details ADD COLUMN is_nonconcurrent INTEGER NOT NULL;
ALTER TABLE qrtz_job_details ADD COLUMN is_update_data INTEGER NOT NULL;

--  SET  RESULTS IN NO COMPLAINT FROM  v8
UPDATE qrtz_job_details SET is_nonconcurrent = is_stateful;
UPDATE qrtz_job_details SET is_update_data = is_stateful;


--   SKIP DROP COLUMN.   See note above concerning lack of DROP COLUMN support
--ALTER TABLE qrtz_job_details DROP COLUMN is_stateful;


ALTER TABLE qrtz_fired_triggers ADD COLUMN is_nonconcurrent INTEGER;
ALTER TABLE qrtz_fired_triggers ADD COLUMN is_update_data INTEGER;
UPDATE qrtz_fired_triggers SET is_nonconcurrent = is_stateful;
UPDATE qrtz_fired_triggers SET is_update_data = is_stateful;


--   SKIP DROP COLUMN.   See note above concerning lack of DROP COLUMN support
--ALTER TABLE qrtz_fired_triggers DROP COLUMN is_stateful;


--
-- 2012-03-22 thorick chow: we set the default value of PRIORITY according to docs at:
--  http://quartz-scheduler.org/api/2.0.0/org/quartz/Trigger.html#DEFAULT_PRIORITY
--
ALTER TABLE qrtz_triggers ADD COLUMN PRIORITY INTEGER;
ALTER TABLE qrtz_fired_triggers ADD COLUMN PRIORITY INTEGER NOT NULL DEFAULT 5;

-- 
--  add new 'sched_name' column to all tables
-- 
ALTER TABLE qrtz_blob_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_calendars ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_cron_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_fired_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_job_details ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_locks ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_paused_trigger_grps ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_scheduler_state ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_simple_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler';

-- 
--  drop all primary and foreign key constraints, so that we can define new ones
--
DROP PROCEDURE JS_DROP_FK_CONSTRAINT;
CREATE PROCEDURE  JS_DROP_FK_CONSTRAINT
  (IN tabNameInput VARCHAR(30))
    LANGUAGE SQL
    BEGIN
        DECLARE SQLSTATE CHAR(5);--
        DECLARE v_constname VARCHAR(128);--
        DECLARE stmt VARCHAR(1000);--
        DECLARE not_found CONDITION FOR SQLSTATE '02000';--
        DECLARE at_end INT DEFAULT 0;--

        DECLARE c1 CURSOR FOR
            SELECT t.CONSTNAME
            FROM SYSCAT.REFERENCES t
            WHERE t.TABNAME=tabNameInput;--

        DECLARE CONTINUE HANDLER FOR not_found
            SET at_end = 1;--

        OPEN c1;--
        ins_loop:
           LOOP
             FETCH c1 INTO v_constname;--
             IF at_end = 1 THEN
               LEAVE ins_loop;--
             END IF;--
             SET stmt = 'ALTER TABLE '|| tabNameInput ||
                 ' DROP CONSTRAINT ' || v_constname;--
             PREPARE s1 FROM stmt;--
             EXECUTE s1;--
             LEAVE ins_loop;--
           END LOOP;--
        CLOSE c1;--
    END;


CALL JS_DROP_FK_CONSTRAINT('QRTZ_SIMPLE_TRIGGERS');


-- drop index, no user maintained index, there's only system SYSIBM index
ALTER TABLE qrtz_simple_triggers DROP PRIMARY KEY;
REORG TABLE qrtz_simple_triggers;

CALL JS_DROP_FK_CONSTRAINT('QRTZ_BLOB_TRIGGERS');
-- drop index, no user maintained index, there's only system SYSIBM index
ALTER TABLE  qrtz_blob_triggers DROP PRIMARY KEY;
REORG TABLE  qrtz_blob_triggers;

CALL JS_DROP_FK_CONSTRAINT('QRTZ_CRON_TRIGGERS');
-- drop index, no user maintained index, there's only system SYSIBM index
ALTER TABLE  qrtz_cron_triggers DROP PRIMARY KEY;
REORG TABLE  qrtz_cron_triggers;

CALL JS_DROP_FK_CONSTRAINT('QRTZ_TRIGGERS');
-- drop index, no user maintained index, there's only system SYSIBM index
ALTER TABLE  qrtz_triggers DROP PRIMARY KEY;
REORG TABLE  qrtz_triggers;


-- we're done with the FK dropping sproc now

DROP PROCEDURE JS_DROP_FK_CONSTRAINT;


ALTER TABLE  qrtz_job_details DROP PRIMARY KEY;
REORG TABLE  qrtz_job_details;

ALTER TABLE  qrtz_fired_triggers DROP PRIMARY KEY;
REORG TABLE  qrtz_fired_triggers;

ALTER TABLE  qrtz_calendars DROP PRIMARY KEY;
REORG TABLE  qrtz_calendars;

ALTER TABLE  qrtz_locks DROP PRIMARY KEY;
REORG TABLE  qrtz_locks;

ALTER TABLE  qrtz_paused_trigger_grps DROP PRIMARY KEY;
REORG TABLE  qrtz_paused_trigger;

ALTER TABLE  qrtz_scheduler_state DROP PRIMARY KEY;
REORG TABLE  qrtz_scheduler_state;

-- 
--  add all primary and foreign key constraints, based on new columns
-- 
ALTER TABLE qrtz_job_details ADD PRIMARY KEY  (sched_name, job_name, job_group);
ALTER TABLE qrtz_triggers ADD PRIMARY KEY  (sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_triggers ADD FOREIGN KEY  (sched_name, job_name, job_group) REFERENCES qrtz_job_details(sched_name, job_name, job_group);
ALTER TABLE qrtz_blob_triggers ADD PRIMARY KEY  (sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_blob_triggers ADD FOREIGN KEY  (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_cron_triggers ADD PRIMARY KEY  (sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_cron_triggers ADD FOREIGN KEY  (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_simple_triggers ADD PRIMARY KEY  (sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_simple_triggers ADD FOREIGN KEY  (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_fired_triggers ADD PRIMARY KEY  (sched_name, entry_id);
ALTER TABLE qrtz_calendars ADD PRIMARY KEY  (sched_name, calendar_name);
ALTER TABLE qrtz_locks ADD PRIMARY KEY  (sched_name, lock_name);
ALTER TABLE qrtz_paused_trigger_grps ADD PRIMARY KEY  (sched_name, trigger_group);
ALTER TABLE qrtz_scheduler_state ADD PRIMARY KEY  (sched_name, instance_name);

-- 
--  add new simprop_triggers table
--
--  NULL constraints on cols 3-end removed.
--  DB2 v8.2 for Windows doesn't like them per v8 create script  quartz_db2_v8.ddl
--
CREATE TABLE qrtz_simprop_triggers
 (          
    SCHED_NAME VARCHAR(100) NOT NULL,
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
    BOOL_PROP_1 INTEGER,
    BOOL_PROP_2 INTEGER,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
    REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

-- 
--  create indexes for faster queries
--
CREATE INDEX ix_qrtz_j_rc ON qrtz_job_details(SCHED_NAME,REQUESTS_RECOVERY);
CREATE INDEX ix_qrtz_j_grp ON qrtz_job_details(SCHED_NAME,JOB_GROUP);
CREATE INDEX ix_qrtz_t_j ON qrtz_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX ix_qrtz_t_jg ON qrtz_triggers(SCHED_NAME,JOB_GROUP);
CREATE INDEX ix_qrtz_t_c ON qrtz_triggers(SCHED_NAME,CALENDAR_NAME);
CREATE INDEX ix_qrtz_t_g ON qrtz_triggers(SCHED_NAME,TRIGGER_GROUP);
CREATE INDEX ix_qrtz_t_state ON qrtz_triggers(SCHED_NAME,TRIGGER_STATE);
CREATE INDEX ix_qrtz_tn_state ON qrtz_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX ix_qrtz_tng_state ON qrtz_triggers(SCHED_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX ix_qrtz_t_nf ON qrtz_triggers(SCHED_NAME,NEXT_FIRE_TIME);
CREATE INDEX ix_qrtz_t_nf_st ON qrtz_triggers(SCHED_NAME,TRIGGER_STATE,NEXT_FIRE_TIME);
CREATE INDEX ix_qrtz_t_nf_mf ON qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME);
CREATE INDEX ix_qrtz_t_nf_stmf ON qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_STATE);
CREATE INDEX ix_qrtz_t_nf_stmfg ON qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX ix_qrtz_ft_tr_name ON qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME);
CREATE INDEX ix_qrtz_ft_it_j_rc ON qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME,REQUESTS_RECOVERY);
CREATE INDEX ix_qrtz_ft_j_g ON qrtz_fired_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX ix_qrtz_ft_jg ON qrtz_fired_triggers(SCHED_NAME,JOB_GROUP);
CREATE INDEX ix_qrtz_ft_t_g ON qrtz_fired_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP);
CREATE INDEX ix_qrtz_ft_tg ON qrtz_fired_triggers(SCHED_NAME,TRIGGER_GROUP);

