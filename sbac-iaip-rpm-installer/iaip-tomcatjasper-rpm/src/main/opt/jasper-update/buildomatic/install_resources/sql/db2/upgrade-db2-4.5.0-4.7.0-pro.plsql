CREATE PROCEDURE EXECBOTH2 (
    in stmt1 varchar(1024),
    in stmt2 varchar(1024)
    )
  LANGUAGE SQL
  begin
    EXECUTE IMMEDIATE stmt1;  
    call "SYSPROC"."ADMIN_CMD"(stmt2);  
  end
/

CREATE PROCEDURE EXECBOTH (
    in stmt1 varchar(1024),
    in stmt2 varchar(1024)
    )
  LANGUAGE SQL
  begin
    call "SYSPROC"."ADMIN_CMD"(stmt1);  
    EXECUTE IMMEDIATE stmt2;  
  end
/

--
-- drop tables that are no longer used
-- 
DROP TABLE qrtz_job_listeners
/
DROP TABLE qrtz_trigger_listeners
/
-- 
--  drop columns that are no longer used
-- 
begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'ALTER TABLE "'||sch||'"."QRTZ_JOB_DETAILS" DROP COLUMN is_volatile';
  set stmt2 = 'REORG TABLE "'||sch||'"."QRTZ_JOB_DETAILS"';
  set stmt3 = 'call "'||sch||'"."EXECBOTH2"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/ 

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'ALTER TABLE "'||sch||'"."QRTZ_TRIGGERS" DROP COLUMN is_volatile';
  set stmt2 = 'REORG TABLE "'||sch||'"."QRTZ_TRIGGERS"';
  set stmt3 = 'call "'||sch||'"."EXECBOTH2"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/ 

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'ALTER TABLE "'||sch||'"."QRTZ_FIRED_TRIGGERS" DROP COLUMN is_volatile';
  set stmt2 = 'REORG TABLE "'||sch||'"."QRTZ_FIRED_TRIGGERS"';
  set stmt3 = 'call "'||sch||'"."EXECBOTH2"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'ALTER TABLE "'||sch||'"."JIREPORTJOBREPODEST" ALTER COLUMN folder_uri DROP NOT NULL';
  set stmt2 = 'REORG TABLE "'||sch||'"."JIREPORTJOBREPODEST"';
  set stmt3 = 'call "'||sch||'"."EXECBOTH2"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/

-- 
--  add new columns and columns that replace 'is_stateful'
--
ALTER TABLE qrtz_job_details ADD COLUMN is_nonconcurrent Smallint NOT NULL DEFAULT
/
ALTER TABLE qrtz_job_details ADD COLUMN is_update_data Smallint NOT NULL DEFAULT
/
update qrtz_job_details SET is_nonconcurrent = is_stateful
/
update qrtz_job_details SET is_update_data = is_stateful
/
ALTER TABLE qrtz_job_details DROP COLUMN is_stateful
/
ALTER TABLE qrtz_fired_triggers ADD COLUMN is_nonconcurrent integer
/
ALTER TABLE qrtz_fired_triggers ADD COLUMN is_update_data Smallint
/
update qrtz_fired_triggers SET is_nonconcurrent = is_stateful
/
update qrtz_fired_triggers SET is_update_data = is_stateful
/
ALTER TABLE qrtz_fired_triggers DROP COLUMN is_stateful
/
ALTER TABLE qrtz_triggers ADD COLUMN PRIORITY integer NULL
/

-- 2012-03-22 thorick chow: we set the default value od PRIORITY according to docs at:
--  http://quartz-scheduler.org/api/2.0.0/org/quartz/Trigger.html#DEFAULT_PRIORITY

ALTER TABLE qrtz_fired_triggers ADD COLUMN PRIORITY integer NOT NULL DEFAULT 5
/
UPDATE qrtz_fired_triggers SET PRIORITY = 5
/
-- 
--  add new 'sched_name' column to all tables
-- 
ALTER TABLE qrtz_blob_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_calendars ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_calendars ALTER COLUMN CALENDAR SET NOT NULL
/
-- ALTER TABLE qrtz_calendars ALTER COLUMN CALENDAR SET DEFAULT 'TestScheduler'
-- /
ALTER TABLE qrtz_calendars ALTER COLUMN CALENDAR SET DATA TYPE blob(4000)
/
ALTER TABLE qrtz_cron_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_fired_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_job_details ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_locks ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_paused_trigger_grps ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_scheduler_state ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_simple_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
ALTER TABLE qrtz_triggers ADD COLUMN SCHED_NAME varchar(100) NOT NULL DEFAULT 'TestScheduler'
/
-- 
--  drop all primary and foreign key constraints, so that we can define new ones
-- 

CREATE PROCEDURE DROPCONST (
    in schemaname varchar(128),
    in tablename varchar(128),
    in type varchar(1)
    )
  LANGUAGE SQL
  begin
    declare stmt        varchar(1024);
    declare dstmt       varchar(1024);
    declare name        varchar(128);
    declare dropstmt    varchar(1024);

    declare mycur cursor WITH RETURN for dstmt;

    set stmt = 'select CONSTNAME from SYSCAT.TABCONST WHERE TABNAME='''||tablename||''' AND TABSCHEMA='''||schemaname||''' AND TYPE='''||type||''' ';

    PREPARE dstmt FROM stmt;    
    open mycur;
    fetch mycur into name;
    close mycur;

    IF name IS NOT NULL THEN
      set dropstmt = 'ALTER TABLE "'||schemaname||'"."'||tablename||'" DROP CONSTRAINT '||name;
      EXECUTE IMMEDIATE dropstmt;
      
    END IF;
  end
/

begin
  declare tbl varchar(128);
  declare sch varchar(128);
  declare type varchar(1);
  declare stmt varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);

  set tbl='QRTZ_BLOB_TRIGGERS';
  set type='F';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_BLOB_TRIGGERS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_SIMPLE_TRIGGERS';
  set type='F';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_SIMPLE_TRIGGERS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_CRON_TRIGGERS';
  set type='F';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_CRON_TRIGGERS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_TRIGGERS';
  set type='F';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_TRIGGERS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_JOB_DETAILS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_FIRED_TRIGGERS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_CALENDARS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_LOCKS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_PAUSED_TRIGGER_GRPS';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set tbl='QRTZ_SCHEDULER_STATE';
  set type='P';
  set stmt = 'call "'||sch||'"."DROPCONST"('''||sch||''','''||tbl||''','''||type||''')';
  EXECUTE IMMEDIATE stmt;

  set stmt = 'DROP PROCEDURE "'||sch||'"."DROPCONST"';
  EXECUTE IMMEDIATE stmt;
  
end
/

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_JOB_DETAILS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_JOB_DETAILS" ADD PRIMARY KEY (sched_name, job_name, job_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_TRIGGERS" ADD PRIMARY KEY (sched_name, trigger_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_TRIGGERS" ADD FOREIGN KEY (sched_name, job_name, job_group) REFERENCES  qrtz_job_details(sched_name, job_name, job_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_BLOB_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_BLOB_TRIGGERS" ADD PRIMARY KEY (sched_name, trigger_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_BLOB_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_BLOB_TRIGGERS" ADD FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES  qrtz_triggers(sched_name, trigger_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_CRON_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_CRON_TRIGGERS" ADD PRIMARY KEY (sched_name, trigger_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_CRON_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_CRON_TRIGGERS" ADD FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES  qrtz_triggers(sched_name, trigger_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_SIMPLE_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_SIMPLE_TRIGGERS" ADD PRIMARY KEY (sched_name, trigger_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_SIMPLE_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_SIMPLE_TRIGGERS" ADD FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES  qrtz_triggers(sched_name, trigger_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_FIRED_TRIGGERS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_FIRED_TRIGGERS" ADD PRIMARY KEY (sched_name, entry_id)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_CALENDARS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_CALENDARS" ADD PRIMARY KEY (sched_name, calendar_name)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_LOCKS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_LOCKS" ADD PRIMARY KEY (sched_name, lock_name)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_PAUSED_TRIGGER_GRPS"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_PAUSED_TRIGGER_GRPS" ADD PRIMARY KEY (sched_name, trigger_group)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/  

begin
  declare stmt1 varchar(1024);
  declare stmt2 varchar(1024);
  declare stmt3 varchar(1024);
  declare sch varchar(128);
  set sch=TRIM(CURRENT_SCHEMA);
  set stmt1 = 'REORG TABLE "'||sch||'"."QRTZ_SCHEDULER_STATE"';
  set stmt2 = 'ALTER TABLE "'||sch||'"."QRTZ_SCHEDULER_STATE" ADD PRIMARY KEY (sched_name, instance_name)';
  set stmt3 = 'call "'||sch||'"."EXECBOTH"('''||stmt1||''','''||stmt2||''')';
  EXECUTE IMMEDIATE stmt3;
end
/

begin
    declare stmt varchar(1024);
    declare sch varchar(128);
    set sch=TRIM(CURRENT_SCHEMA);
    set stmt = 'DROP PROCEDURE "'||sch||'"."EXECBOTH"';
    EXECUTE IMMEDIATE stmt;
end
/

begin
    declare stmt varchar(1024);
    declare sch varchar(128);
    set sch=TRIM(CURRENT_SCHEMA);
    set stmt = 'DROP PROCEDURE "'||sch||'"."EXECBOTH2"';
    EXECUTE IMMEDIATE stmt;
end
/



-- 
--  add new simprop_triggers table
-- 
CREATE TABLE qrtz_simprop_triggers
 (          
    SCHED_NAME VARCHAR(100) NOT NULL,
    TRIGGER_NAME VARCHAR(80) NOT NULL,
    TRIGGER_GROUP VARCHAR(80) NOT NULL,
    STR_PROP_1 VARCHAR(512) NULL,
    STR_PROP_2 VARCHAR(512) NULL,
    STR_PROP_3 VARCHAR(512) NULL,
    INT_PROP_1 INT NULL,
    INT_PROP_2 INT NULL,
    LONG_PROP_1 BIGINT NULL,
    LONG_PROP_2 BIGINT NULL,
    DEC_PROP_1 NUMERIC(13,4) NULL,
    DEC_PROP_2 NUMERIC(13,4) NULL,
    BOOL_PROP_1 INTEGER,
    BOOL_PROP_2 INTEGER,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
    REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
)
/
-- 
--  CREATE INDEX es for faster queries
-- 
CREATE INDEX  idx_qrtz_j_req_recovery on qrtz_job_details(SCHED_NAME,REQUESTS_RECOVERY)
/
CREATE INDEX  idx_qrtz_j_grp on qrtz_job_details(SCHED_NAME,JOB_GROUP)
/
CREATE INDEX  idx_qrtz_t_j on qrtz_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP)
/
CREATE INDEX  idx_qrtz_t_jg on qrtz_triggers(SCHED_NAME,JOB_GROUP)
/
CREATE INDEX  idx_qrtz_t_c on qrtz_triggers(SCHED_NAME,CALENDAR_NAME)
/
CREATE INDEX  idx_qrtz_t_g on qrtz_triggers(SCHED_NAME,TRIGGER_GROUP)
/
CREATE INDEX  idx_qrtz_t_state on qrtz_triggers(SCHED_NAME,TRIGGER_STATE)
/
CREATE INDEX  idx_qrtz_t_n_state on qrtz_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_STATE)
/
CREATE INDEX  idx_qrtz_t_n_g_state on qrtz_triggers(SCHED_NAME,TRIGGER_GROUP,TRIGGER_STATE)
/
CREATE INDEX  idx_qrtz_t_next_fire_time on qrtz_triggers(SCHED_NAME,NEXT_FIRE_TIME)
/
CREATE INDEX  idx_qrtz_t_nft_st on qrtz_triggers(SCHED_NAME,TRIGGER_STATE,NEXT_FIRE_TIME)
/
CREATE INDEX  idx_qrtz_t_nft_misfire on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME)
/
CREATE INDEX  idx_qrtz_t_nft_st_misfire on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_STATE)
/
CREATE INDEX  idx_qrtz_t_nft_st_misfire_grp on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_GROUP,TRIGGER_STATE)
/
CREATE INDEX  idx_qrtz_ft_trig_inst_name on qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME)
/
CREATE INDEX  idx_qrtz_ft_inst_job_req_rcvry on qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME,REQUESTS_RECOVERY)
/
CREATE INDEX  idx_qrtz_ft_j_g on qrtz_fired_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP)
/
CREATE INDEX  idx_qrtz_ft_jg on qrtz_fired_triggers(SCHED_NAME,JOB_GROUP)
/
CREATE INDEX  idx_qrtz_ft_t_g on qrtz_fired_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
/
CREATE INDEX  idx_qrtz_ft_tg on qrtz_fired_triggers(SCHED_NAME,TRIGGER_GROUP)
/
