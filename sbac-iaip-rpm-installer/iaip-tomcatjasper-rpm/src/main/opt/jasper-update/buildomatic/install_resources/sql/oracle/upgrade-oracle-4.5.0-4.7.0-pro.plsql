-- 2012-03-21  thorick chow:  todo:  make a few PL/SQL procedures to remove duplicate code
--                       time is tight, not enough of a PL/SQL hack to whip it out
--                       quickly for now.

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
ALTER TABLE qrtz_job_details DROP COLUMN is_volatile
/
ALTER TABLE qrtz_triggers DROP COLUMN is_volatile
/
ALTER TABLE qrtz_fired_triggers DROP COLUMN is_volatile
/
-- 
--  add new columns and columns that replace is_stateful
-- 

ALTER TABLE qrtz_job_details ADD (is_nonconcurrent VARCHAR2(1))
/
ALTER TABLE qrtz_job_details ADD (is_update_data VARCHAR2(1))
/
UPDATE qrtz_job_details SET is_nonconcurrent = is_stateful
/
UPDATE qrtz_job_details SET is_update_data = is_stateful
/
ALTER TABLE qrtz_job_details MODIFY (is_nonconcurrent VARCHAR2(1) NOT NULL)
/
ALTER TABLE qrtz_job_details MODIFY (is_update_data VARCHAR2(1) NOT NULL)
/
ALTER TABLE qrtz_job_details DROP COLUMN is_stateful
/
ALTER TABLE qrtz_fired_triggers ADD (is_nonconcurrent VARCHAR2(1) NULL)
/
ALTER TABLE qrtz_fired_triggers ADD (is_update_data VARCHAR2(1) NULL)
/
UPDATE qrtz_fired_triggers SET is_nonconcurrent = is_stateful
/
UPDATE qrtz_fired_triggers SET is_update_data = is_stateful
/
ALTER TABLE qrtz_fired_triggers DROP COLUMN is_stateful
/
ALTER TABLE qrtz_triggers ADD (PRIORITY NUMBER(13) NULL)
/

-- 2012-03-22 thorick chow: we set the default value of PRIORITY according to docs at:
-- http://quartz-scheduler.org/api/2.0.0/org/quartz/Trigger.html#DEFAULT_PRIORITY

ALTER TABLE qrtz_fired_triggers ADD (PRIORITY NUMBER(13) NOT NULL)
/
UPDATE qrtz_fired_triggers SET PRIORITY = 5
/

-- 
--  add new sched_name column to all tables
-- 
ALTER TABLE qrtz_blob_triggers ADD (SCHED_NAME varchar(100) DEFAULT 'TestScheduler'  NOT NULL)
/
ALTER TABLE qrtz_calendars ADD (SCHED_NAME varchar(100) DEFAULT 'TestScheduler' NOT NULL )
/
ALTER TABLE qrtz_cron_triggers ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/
ALTER TABLE qrtz_fired_triggers ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/
ALTER TABLE qrtz_job_details ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/
ALTER TABLE qrtz_locks ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/
ALTER TABLE qrtz_paused_trigger_grps ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/
ALTER TABLE qrtz_scheduler_state ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/
ALTER TABLE qrtz_simple_triggers ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/
ALTER TABLE qrtz_triggers ADD (SCHED_NAME varchar(100)DEFAULT 'TestScheduler' NOT NULL)
/


-- 
--  drop all primary and foreign key constraints, so that we can define new ones
-- 

DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
  SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
    join user_cons_columns rel
      on cc.r_constraint_name = rel.constraint_name
     and con.position = rel.position
WHERE
    cc.constraint_type = 'R'
    and col.column_name = 'TRIGGER_NAME'
    and col.table_name = 'QRTZ_BLOB_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_BLOB_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/


-- oracle table has no index
--alter table qrtz_blob_triggers drop index trigger_name;

--alter table qrtz_blob_triggers drop constraint qrtz_blob_triggers_pkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
  SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'TRIGGER_NAME'
    and col.table_name = 'QRTZ_BLOB_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_BLOB_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/

--alter table qrtz_simple_triggers drop constraint qrtz_simple_triggers_trigger_name_fkey;

DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
  SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
    join user_cons_columns rel
      on cc.r_constraint_name = rel.constraint_name
     and con.position = rel.position
WHERE
    cc.constraint_type = 'R'
    and col.column_name = 'TRIGGER_NAME'
    and col.table_name = 'QRTZ_SIMPLE_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_SIMPLE_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/


-- oracle table has index, but we didn't do 'CREATE INDEX' ??
--  A:  it's a system created index that gets dropped automatically  with the PK constraint
--alter table qrtz_simple_triggers drop index trigger_name;


--alter table qrtz_simple_triggers drop constraint qrtz_simple_triggers_pkey;

DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'TRIGGER_NAME'
    and col.table_name = 'QRTZ_SIMPLE_TRIGGERS';


   statement := 'ALTER TABLE  QRTZ_SIMPLE_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/




--alter table qrtz_cron_triggers drop constraint qrtz_cron_triggers_trigger_name_fkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
  SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
    join user_cons_columns rel
      on cc.r_constraint_name = rel.constraint_name
     and con.position = rel.position
WHERE
    cc.constraint_type = 'R'
    and col.column_name = 'TRIGGER_NAME'
    and col.table_name = 'QRTZ_CRON_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_CRON_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/


-- oracle table has index
--alter table qrtz_cron_triggers drop index trigger_name;
--alter table qrtz_cron_triggers drop constraint qrtz_cron_triggers_pkey;

DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'TRIGGER_NAME'
    and col.table_name = 'QRTZ_CRON_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_CRON_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/



--alter table qrtz_triggers drop constraint qrtz_triggers_job_name_fkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
  SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
    join user_cons_columns rel
      on cc.r_constraint_name = rel.constraint_name
     and con.position = rel.position
WHERE
    cc.constraint_type = 'R'
    and col.column_name = 'JOB_NAME'
    and col.table_name = 'QRTZ_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/

DROP index idx_qrtz_ft_trig_inst_name
/
DROP index idx_qrtz_j_req_recovery
/
DROP index idx_qrtz_t_next_fire_time
/
DROP index idx_qrtz_t_state
/
DROP index idx_qrtz_t_nft_st
/

DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'TRIGGER_NAME'
    and col.table_name = 'QRTZ_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/


--alter table qrtz_job_details drop constraint qrtz_job_details_pkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'JOB_NAME'
    and col.table_name = 'QRTZ_JOB_DETAILS';

   statement := 'ALTER TABLE  QRTZ_JOB_DETAILS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/


--alter table qrtz_fired_triggers drop constraint qrtz_fired_triggers_pkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'ENTRY_ID'
    and col.table_name = 'QRTZ_FIRED_TRIGGERS';

   statement := 'ALTER TABLE  QRTZ_FIRED_TRIGGERS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/



--alter table qrtz_calendars drop constraint qrtz_calendars_pkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'CALENDAR_NAME'
    and col.table_name = 'QRTZ_CALENDARS';

   statement := 'ALTER TABLE  QRTZ_CALENDARS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/



--alter table qrtz_locks drop constraint qrtz_locks_pkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'LOCK_NAME'
    and col.table_name = 'QRTZ_LOCKS';

   statement := 'ALTER TABLE  QRTZ_LOCKS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/



--alter table qrtz_paused_trigger_grps drop constraint qrtz_paused_trigger_grps_pkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'TRIGGER_GROUP'
    and col.table_name = 'QRTZ_PAUSED_TRIGGER_GRPS';

   statement := 'ALTER TABLE  QRTZ_PAUSED_TRIGGER_GRPS  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/



--alter table qrtz_scheduler_state drop constraint qrtz_scheduler_state_pkey;
DECLARE
statement VARCHAR2(2000);
constr_name VARCHAR2(30);
BEGIN
 SELECT cc.CONSTRAINT_NAME INTO constr_name
FROM
    user_tab_columns col
    join user_cons_columns con
      on col.table_name = con.table_name
     and col.column_name = con.column_name
    join user_constraints cc
      on con.constraint_name = cc.constraint_name
WHERE
    cc.constraint_type = 'P'
    and col.column_name = 'INSTANCE_NAME'
    and col.table_name = 'QRTZ_SCHEDULER_STATE';

   statement := 'ALTER TABLE  QRTZ_SCHEDULER_STATE  DROP CONSTRAINT '|| constr_name;
   EXECUTE IMMEDIATE(statement);
END;
/


-- 
--  add all primary and foreign key constraints, based on new columns
-- 

ALTER TABLE qrtz_job_details ADD CONSTRAINT qrtz_job_details_pk PRIMARY KEY(sched_name, job_name, job_group)
/
ALTER TABLE qrtz_triggers ADD CONSTRAINT qrtz_triggers_pk PRIMARY KEY (sched_name, trigger_name, trigger_group)
/
ALTER TABLE qrtz_triggers ADD CONSTRAINT qrtz_triggers_details_fk  FOREIGN KEY (sched_name, job_name, job_group) REFERENCES qrtz_job_details(sched_name, job_name, job_group)
/
ALTER TABLE qrtz_blob_triggers ADD CONSTRAINT qrtz_blob_triggers_pk PRIMARY KEY (sched_name, trigger_name, trigger_group)
/
ALTER TABLE qrtz_blob_triggers ADD CONSTRAINT qrtz_blob_triggers_triggers_fk  FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group)
/
ALTER TABLE qrtz_cron_triggers ADD CONSTRAINT qrtz_cron_triggers_pk PRIMARY KEY (sched_name, trigger_name, trigger_group)
/
ALTER TABLE qrtz_cron_triggers ADD CONSTRAINT qrtz_cron_triggers_triggers_fk  FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group)
/
ALTER TABLE qrtz_simple_triggers ADD CONSTRAINT qrtz_simple_triggers_pk PRIMARY KEY (sched_name, trigger_name, trigger_group)
/
ALTER TABLE qrtz_simple_triggers ADD CONSTRAINT qrtz_simple_triggers_tr_fk FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group)
/
ALTER TABLE qrtz_fired_triggers ADD CONSTRAINT qrtz_fired_triggers_pk PRIMARY KEY (sched_name, entry_id)
/
ALTER TABLE qrtz_calendars ADD CONSTRAINT qrtz_calendars_pk PRIMARY KEY (sched_name, calendar_name)
/
ALTER TABLE qrtz_locks ADD CONSTRAINT qrtz_locks_pk PRIMARY KEY (sched_name, lock_name)
/
ALTER TABLE qrtz_paused_trigger_grps ADD CONSTRAINT qrtz_paused_trigger_grps_pk PRIMARY KEY (sched_name, trigger_group)
/
ALTER TABLE qrtz_scheduler_state ADD CONSTRAINT qrtz_scheduler_state_pk PRIMARY KEY (sched_name, instance_name)
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
    LONG_PROP_1 NUMBER(19) NULL,
    LONG_PROP_2 NUMBER(19) NULL,
    DEC_PROP_1 NUMERIC(13,4) NULL,
    DEC_PROP_2 NUMERIC(13,4) NULL,
    BOOL_PROP_1 VARCHAR2(1) NULL,
    BOOL_PROP_2 VARCHAR2(1) NULL,
    CONSTRAINT qrtz_simprop_triggers_pkey PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    CONSTRAINT qrtz_simprop_triggers_fkey FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
    REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
)
/
-- 
--  CREATE INDEXes for faster queries
-- 
CREATE INDEX idx_qrtz_j_req_recovery on qrtz_job_details(SCHED_NAME,REQUESTS_RECOVERY)
/
CREATE INDEX idx_qrtz_j_grp on qrtz_job_details(SCHED_NAME,JOB_GROUP)
/
CREATE INDEX idx_qrtz_t_j on qrtz_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP)
/
CREATE INDEX idx_qrtz_t_jg on qrtz_triggers(SCHED_NAME,JOB_GROUP)
/
CREATE INDEX idx_qrtz_t_c on qrtz_triggers(SCHED_NAME,CALENDAR_NAME)
/
CREATE INDEX idx_qrtz_t_g on qrtz_triggers(SCHED_NAME,TRIGGER_GROUP)
/
CREATE INDEX idx_qrtz_t_state on qrtz_triggers(SCHED_NAME,TRIGGER_STATE)
/
CREATE INDEX idx_qrtz_t_n_state on qrtz_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_STATE)
/
CREATE INDEX idx_qrtz_t_n_g_state on qrtz_triggers(SCHED_NAME,TRIGGER_GROUP,TRIGGER_STATE)
/
CREATE INDEX idx_qrtz_t_next_fire_time on qrtz_triggers(SCHED_NAME,NEXT_FIRE_TIME)
/
CREATE INDEX idx_qrtz_t_nft_st on qrtz_triggers(SCHED_NAME,TRIGGER_STATE,NEXT_FIRE_TIME)
/
CREATE INDEX idx_qrtz_t_nft_misfire on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME)
/
CREATE INDEX idx_qrtz_t_nft_st_misfire on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_STATE)
/
CREATE INDEX idx_qrtz_t_nft_st_misfire_grp on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_GROUP,TRIGGER_STATE)
/
CREATE INDEX idx_qrtz_ft_trig_inst_name on qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME)
/
CREATE INDEX idx_qrtz_ft_inst_job_req_rcvry on qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME,REQUESTS_RECOVERY)
/
CREATE INDEX idx_qrtz_ft_j_g on qrtz_fired_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP)
/
CREATE INDEX idx_qrtz_ft_jg on qrtz_fired_triggers(SCHED_NAME,JOB_GROUP)
/
CREATE INDEX idx_qrtz_ft_t_g on qrtz_fired_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
/
CREATE INDEX idx_qrtz_ft_tg on qrtz_fired_triggers(SCHED_NAME,TRIGGER_GROUP)
/
