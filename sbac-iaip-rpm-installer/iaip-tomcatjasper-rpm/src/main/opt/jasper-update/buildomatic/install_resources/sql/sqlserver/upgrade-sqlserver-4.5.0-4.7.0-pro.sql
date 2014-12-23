-- this script has been updated to fix a 4.7.0 bug #28757
-- so in effect this is a 4.5.0 to 4.7.1 upgrade script

--
-- add resourceType column to jiresource table, popolate with data and create index
--

ALTER TABLE JIResource ADD resourceType nvarchar(255);

UPDATE JIResource SET resourceType = substring ( rtype, 6, 1000 )
FROM (
SELECT id, min(resourceType) rtype FROM (
      SELECT id, 'B001_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.BeanReportDataSource' AS resourceType FROM JIBeanDataSource
UNION SELECT id, 'B002_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.CustomReportDataSource' AS resourceType FROM JICustomDataSource
UNION SELECT id, 'B003_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.JdbcReportDataSource' AS resourceType FROM JIJdbcDataSource
UNION SELECT id, 'B004_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.JndiJdbcReportDataSource' AS resourceType FROM JIJndiJdbcDataSource
UNION SELECT id, 'B005_com.jaspersoft.commons.semantic.datasource.SemanticLayerDataSource' AS resourceType FROM JIDomainDatasource
UNION SELECT id, 'B011_com.jaspersoft.ji.ja.security.domain.SecureMondrianConnection' AS resourceType FROM JIMondrianConnection
UNION SELECT id, 'B012_com.jaspersoft.jasperserver.api.metadata.olap.domain.XMLAConnection' AS resourceType FROM JIXMLAConnection
UNION SELECT id, 'B021_com.jaspersoft.ji.adhoc.AdhocReportUnit' AS resourceType FROM JIAdhocReportUnit
UNION SELECT id, 'B022_com.jaspersoft.commons.semantic.DataDefinerUnit' AS resourceType FROM JIDataDefinerUnit
UNION SELECT id, 'C011_com.jaspersoft.jasperserver.api.metadata.common.domain.ContentResource' AS resourceType FROM JIContentResource
UNION SELECT id, 'C012_com.jaspersoft.ji.adhoc.DashboardResource' AS resourceType FROM JIDashboard
UNION SELECT id, 'C013_com.jaspersoft.jasperserver.api.metadata.common.domain.DataType' AS resourceType FROM JIDataType
UNION SELECT id, 'C014_com.jaspersoft.jasperserver.api.metadata.common.domain.FileResource' AS resourceType FROM JIFileResource
UNION SELECT id, 'C015_com.jaspersoft.jasperserver.api.metadata.common.domain.InputControl' AS resourceType FROM JIInputControl
UNION SELECT id, 'C016_com.jaspersoft.jasperserver.api.metadata.common.domain.ListOfValues' AS resourceType FROM JIListOfValues
UNION SELECT id, 'C017_com.jaspersoft.jasperserver.api.metadata.olap.domain.MondrianXMLADefinition' AS resourceType FROM JIMondrianXMLADefinition
UNION SELECT id, 'C018_com.jaspersoft.jasperserver.api.metadata.olap.domain.OlapUnit' AS resourceType FROM JIOlapUnit
UNION SELECT id, 'C019_com.jaspersoft.jasperserver.api.metadata.common.domain.Query' AS resourceType FROM JIQuery
UNION SELECT id, 'C020_com.jaspersoft.ji.report.options.metadata.ReportOptions' AS resourceType FROM JIReportOptions
UNION SELECT id, 'C021_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.ReportUnit' AS resourceType FROM JIReportUnit
) ids GROUP BY id ) data
WHERE JIResource.id = data.id;
ALTER TABLE JIResource ALTER COLUMN resourceType nvarchar(255) NOT NULL;
CREATE INDEX resource_type_index ON JIResource (resourceType);



--
-- alter tables and add data to columns if required
--

-- add and popolate creation_date column to JIReportJob table
ALTER TABLE JIReportJob ADD creation_date datetime;
UPDATE JIReportJob SET creation_date = CURRENT_TIMESTAMP;

-- add alert column to JIReportJob table
ALTER TABLE JIReportJob ADD alert numeric(19,0);

-- add data_snapshot_id column to JIReportUnit table
ALTER TABLE JIReportUnit ADD data_snapshot_id numeric(19,0);

-- add and populate new columns for JIReportJobMail table 
ALTER TABLE JIReportJobMail ADD message_text_when_job_fails nvarchar(2000) null DEFAULT '';
ALTER TABLE JIReportJobMail ADD inc_stktrc_when_job_fails tinyint NOT NULL DEFAULT(0);
ALTER TABLE JIReportJobMail ADD skip_notif_when_job_fails tinyint NOT NULL DEFAULT(0);
UPDATE JIReportJobMail SET inc_stktrc_when_job_fails = 0;
UPDATE JIReportJobMail SET skip_notif_when_job_fails = 0;

-- add and populate new columns for JIReportJobRepoDest table 
ALTER TABLE JIReportJobRepoDest ADD save_to_repository tinyint NOT NULL DEFAULT(1);
ALTER TABLE JIReportJobRepoDest ADD using_def_rpt_opt_folder_uri tinyint NOT NULL DEFAULT(0);
ALTER TABLE JIReportJobRepoDest ADD output_local_folder nvarchar(250);
ALTER TABLE JIReportJobRepoDest ADD user_name nvarchar(50);
ALTER TABLE JIReportJobRepoDest ADD password nvarchar(50);
ALTER TABLE JIReportJobRepoDest ADD server_name nvarchar(150);
ALTER TABLE JIReportJobRepoDest ADD folder_path nvarchar(250);
ALTER TABLE JIReportJobRepoDest ALTER COLUMN folder_uri nvarchar(250) null;
UPDATE JIReportJobRepoDest SET save_to_repository = 1;
UPDATE JIReportJobRepoDest SET using_def_rpt_opt_folder_uri = 0;

-- add new columns for JIReportJobTrigger table 
ALTER TABLE JIReportJobTrigger ADD calendar_name nvarchar(50);
ALTER TABLE JIReportJobTrigger ADD misfire_instruction int DEFAULT(0);
UPDATE JIReportJobTrigger SET misfire_instruction = 0;


--
-- ReportJob tables
--

    create table JIFTPInfoProperties (
        repodest_id numeric(19,0) not null,
        property_value nvarchar(250),
        property_name nvarchar(100) not null,
        primary key (repodest_id, property_name)
    );

    create table JIReportAlertToAddress (
        alert_id numeric(19,0) not null,
        to_address nvarchar(100) not null,
        to_address_idx int not null,
        primary key (alert_id, to_address_idx)
    );

    create table JIReportJobAlert (
        id numeric(19,0) identity not null,
        version int not null,
        recipient tinyint not null,
        subject nvarchar(100),
        message_text nvarchar(2000),
        message_text_when_job_fails nvarchar(2000),
        job_state tinyint not null,
        including_stack_trace tinyint not null,
        including_report_job_info tinyint not null,
        primary key (id)
    );

    alter table JIFTPInfoProperties
        add constraint FK6BD68B04D5FA3F0A
        foreign key (repodest_id)
        references JIReportJobRepoDest;

    alter table JIReportAlertToAddress
        add constraint FKC4E3713022FA4CBA
        foreign key (alert_id)
        references JIReportJobAlert;

    alter table JIReportJob
        add constraint FK156F5F6AC83ABB38
        foreign key (alert)
        references JIReportJobAlert;

--
-- Snapshot tables
--

    create table JIDataSnapshot (
        id numeric(19,0) identity not null,
        version int not null,
        snapshot_date datetime null,
        contents_id numeric(19,0) not null,
        constraint ji_data_snapshot_pkey primary key (id)
    );

    create table JIDataSnapshotContents (
        id numeric(19,0) identity not null,
--        data varbinary not null,
-- this was the original line in 4.5.0 to 4.7.0 script
-- it had been changed in 4.7.1 to fix bug #28757
        data varbinary(max) not null,
        constraint ji_data_snapshot_contents_pkey primary key (id)
    );

    create table JIDataSnapshotParameter (
        id numeric(19,0) not null,
        parameter_value varbinary(max) null,
        parameter_name nvarchar(100) not null,
        constraint ji_data_snapshot_parameter_pkey primary key (id, parameter_name)
    );

    alter table JIDataSnapshotParameter
        add constraint id_fk_idx
        foreign key (id)
        references JIDataSnapshot;
        
--
-- Adhoc tables
--        
    create table JIAdhocDataView (
        id numeric(19,0) not null,
        adhocStateId numeric(19,0),
        reportDataSource numeric(19,0),
        promptcontrols tinyint,
        controlslayout tinyint,
        controlrenderer nvarchar(100),
        constraint ji_adhoc_dataview_pkey primary key (id)
    );

    create table JIAdhocDataViewInputControl (
        adhoc_data_view_id numeric(19,0) not null,
        input_control_id numeric(19,0) not null,
        control_index int not null,
        constraint ji_adhoc_dataview_input_control_pkey primary key (adhoc_data_view_id, control_index)
    );

    create table JIAdhocDataViewResource (
        adhoc_data_view_id numeric(19,0) not null,
        resource_id numeric(19,0) not null,
        resource_index int not null,
        constraint ji_adhoc_dataview_resource_pkey primary key (adhoc_data_view_id, resource_index)
    );

    alter table JIAdhocDataView
        add constraint FK200A2AC9A8BF376D
        foreign key (id)
        references JIResource;

    alter table JIAdhocDataView
        add constraint FK200A2AC9324CFECB
        foreign key (reportDataSource)
        references JIResource;

    alter table JIAdhocDataView
        add constraint FK200A2AC931211827
        foreign key (adhocStateId)
        references JIAdhocState;

    alter table JIAdhocDataViewInputControl
        add constraint FKA248C79CB22FF3B2
        foreign key (adhoc_data_view_id)
        references JIAdhocDataView;

    alter table JIAdhocDataViewInputControl
        add constraint FKA248C79CE7922149
        foreign key (input_control_id)
        references JIInputControl;

    alter table JIAdhocDataViewResource
        add constraint FK98179F7B22FF3B2
        foreign key (adhoc_data_view_id)
        references JIAdhocDataView;

    alter table JIAdhocDataViewResource
        add constraint FK98179F7865B10DA
        foreign key (resource_id)
        references JIFileResource;


--
-- Quartz tables
--

-- PART 1
--
-- drop tables that are no longer used
-- 
DROP TABLE qrtz_job_listeners;
DROP TABLE qrtz_trigger_listeners;
-- 
--  drop columns that are no longer used
-- 
ALTER TABLE qrtz_job_details DROP COLUMN is_volatile;
ALTER TABLE qrtz_triggers DROP COLUMN is_volatile;
ALTER TABLE qrtz_fired_triggers DROP COLUMN is_volatile;
-- 
--  add new columns and columns that replace 'is_stateful'
--
ALTER TABLE qrtz_job_details ADD is_nonconcurrent NVARCHAR(1) NOT NULL DEFAULT(0);
ALTER TABLE qrtz_job_details ADD is_update_data NVARCHAR(1) NOT NULL DEFAULT(0);

--  PART 2
UPDATE qrtz_job_details SET is_nonconcurrent = is_stateful;
UPDATE qrtz_job_details SET is_update_data = is_stateful;

ALTER TABLE qrtz_job_details DROP COLUMN is_stateful;
ALTER TABLE qrtz_fired_triggers ADD is_nonconcurrent NVARCHAR(1) DEFAULT(0);
ALTER TABLE qrtz_fired_triggers ADD is_update_data NVARCHAR(1) DEFAULT(0);

--  PART 3
UPDATE qrtz_fired_triggers SET is_nonconcurrent = is_stateful;
UPDATE qrtz_fired_triggers SET is_update_data = is_stateful;

ALTER TABLE qrtz_fired_triggers DROP COLUMN is_stateful;
ALTER TABLE qrtz_triggers ADD PRIORITY integer null;

-- 2012-03-22 thorick chow: we set the default value of PRIORITY according to docs at:
-- http://quartz-scheduler.org/api/2.0.0/org/quartz/Trigger.html#DEFAULT_PRIORITY

ALTER TABLE qrtz_fired_triggers ADD PRIORITY integer NOT NULL DEFAULT(0);
UPDATE qrtz_fired_triggers SET PRIORITY = 5;

-- 
--  add new 'sched_name' column to all tables
--
ALTER TABLE qrtz_blob_triggers ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_calendars ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_cron_triggers ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_fired_triggers ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_job_details ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_locks ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_paused_trigger_grps ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_scheduler_state ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_simple_triggers ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';
ALTER TABLE qrtz_triggers ADD SCHED_NAME NVARCHAR(100) NOT NULL DEFAULT 'TestScheduler';

-- 
--  drop all primary and foreign key constraints, so that we can define new ones
-- 
-- sqlserver has no fk
--ALTER TABLE qrtz_blob_triggers DROP CONSTRAINT qrtz_blob_triggers_trigger_name_fkey;
-- sqlserver table has no index
--ALTER TABLE qrtz_blob_triggers drop index trigger_name;
-- sqlserver table has no pk (!)
--ALTER TABLE qrtz_blob_triggers DROP CONSTRAINT qrtz_blob_triggers_pkey;


ALTER TABLE qrtz_simple_triggers DROP CONSTRAINT FK_QRTZ_SIMPLE_TRIGGERS_QRTZ_TRIGGERS;
-- dropping PK CONSTRAINT also drops the PK index
ALTER TABLE qrtz_simple_triggers DROP CONSTRAINT PK_QRTZ_SIMPLE_TRIGGERS;


ALTER TABLE qrtz_cron_triggers DROP CONSTRAINT FK_QRTZ_CRON_TRIGGERS_QRTZ_TRIGGERS;
-- dropping PK CONSTRAINT also drops the PK index
ALTER TABLE qrtz_cron_triggers DROP CONSTRAINT PK_QRTZ_CRON_TRIGGERS;


ALTER TABLE qrtz_triggers DROP CONSTRAINT FK_QRTZ_TRIGGERS_QRTZ_JOB_DETAILS;
-- dropping PK CONSTRAINT also drops the PK index
ALTER TABLE qrtz_triggers DROP CONSTRAINT PK_QRTZ_TRIGGERS;


ALTER TABLE qrtz_job_details DROP CONSTRAINT PK_QRTZ_JOB_DETAILS;
ALTER TABLE qrtz_fired_triggers DROP CONSTRAINT PK_QRTZ_FIRED_TRIGGERS;
ALTER TABLE qrtz_calendars DROP CONSTRAINT PK_QRTZ_CALENDARS;
ALTER TABLE qrtz_locks DROP CONSTRAINT PK_QRTZ_LOCKS;
ALTER TABLE qrtz_paused_trigger_grps DROP CONSTRAINT PK_QRTZ_PAUSED_TRIGGER_GRPS;
ALTER TABLE qrtz_scheduler_state DROP CONSTRAINT PK_QRTZ_SCHEDULER_STATE;

--  PART 4
--

--  add all primary and foreign key constraints, based on new columns
-- 
ALTER TABLE qrtz_job_details ADD CONSTRAINT PK_QRTZ_JOB_DETAILS PRIMARY KEY (sched_name, job_name, job_group);
ALTER TABLE qrtz_triggers ADD CONSTRAINT PK_QRTZ_TRIGGERS PRIMARY KEY (sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_triggers ADD CONSTRAINT FK_QRTZ_TRIGGERS_QRTZ_JOB_DETAILS FOREIGN KEY (sched_name, job_name, job_group) REFERENCES qrtz_job_details(sched_name, job_name, job_group);

-- sqlserver has no blob PKs or FKs
--ALTER TABLE qrtz_blob_triggers ADD CONSTRAINT PRIMARY KEY (sched_name, trigger_name, trigger_group);
--ALTER TABLE qrtz_blob_triggers ADD FOREIGN KEY (sched_name, trigger_name, trigger_group) references qrtz_triggers(sched_name, trigger_name, trigger_group);

ALTER TABLE qrtz_cron_triggers ADD CONSTRAINT PK_QRTZ_CRON_TRIGGERS PRIMARY KEY (sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_cron_triggers ADD CONSTRAINT FK_QRTZ_CRON_TRIGGERS_QRTZ_TRIGGERS FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_simple_triggers ADD CONSTRAINT PK_QRTZ_SIMPLE_TRIGGERS PRIMARY KEY (sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_simple_triggers ADD CONSTRAINT FK_QRTZ_SIMPLE_TRIGGERS_QRTZ_TRIGGERS FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES qrtz_triggers(sched_name, trigger_name, trigger_group);
ALTER TABLE qrtz_fired_triggers ADD CONSTRAINT PK_QRTZ_FIRED_TRIGGERS PRIMARY KEY (sched_name, entry_id);
ALTER TABLE qrtz_calendars ADD CONSTRAINT PK_QRTZ_CALENDARS PRIMARY KEY (sched_name, calendar_name);
ALTER TABLE qrtz_locks ADD CONSTRAINT PK_QRTZ_LOCKS PRIMARY KEY (sched_name, lock_name);
ALTER TABLE qrtz_paused_trigger_grps ADD CONSTRAINT PK_QRTZ_PAUSED_TRIGGER_GRPS PRIMARY KEY (sched_name, trigger_group);
ALTER TABLE qrtz_scheduler_state ADD CONSTRAINT PK_QRTZ_SCHEDULER_STATE PRIMARY KEY (sched_name, instance_name);
-- 
--  add new simprop_triggers table
-- 
CREATE TABLE QRTZ_SIMPROP_TRIGGERS
 (
    SCHED_NAME NVARCHAR(100) NOT NULL,
    TRIGGER_NAME NVARCHAR(80) NOT NULL,
    TRIGGER_GROUP NVARCHAR(80) NOT NULL,
    STR_PROP_1 NVARCHAR(512) NULL,
    STR_PROP_2 NVARCHAR(512) NULL,
    STR_PROP_3 NVARCHAR(512) NULL,
    INT_PROP_1 INT NULL,
    INT_PROP_2 INT NULL,
    LONG_PROP_1 BIGINT NULL,
    LONG_PROP_2 BIGINT NULL,
    DEC_PROP_1 NUMERIC(13,4) NULL,
    DEC_PROP_2 NUMERIC(13,4) NULL,
    BOOL_PROP_1 NVARCHAR(1) NULL,
    BOOL_PROP_2 NVARCHAR(1) NULL,
    CONSTRAINT QRTZ_SIMPROP_TRIGGERS_PKEY PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    CONSTRAINT QRTZ_SIMPROP_TRIGGERS_FKEY FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
    REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);
-- 
--  CREATE INDEXes for faster queries
-- 
CREATE INDEX idx_qrtz_j_req_recovery on qrtz_job_details(SCHED_NAME,REQUESTS_RECOVERY);
CREATE INDEX idx_qrtz_j_grp on qrtz_job_details(SCHED_NAME,JOB_GROUP);
CREATE INDEX idx_qrtz_t_j on qrtz_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX idx_qrtz_t_jg on qrtz_triggers(SCHED_NAME,JOB_GROUP);
CREATE INDEX idx_qrtz_t_c on qrtz_triggers(SCHED_NAME,CALENDAR_NAME);
CREATE INDEX idx_qrtz_t_g on qrtz_triggers(SCHED_NAME,TRIGGER_GROUP);
CREATE INDEX idx_qrtz_t_state on qrtz_triggers(SCHED_NAME,TRIGGER_STATE);
CREATE INDEX idx_qrtz_t_n_state on qrtz_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX idx_qrtz_t_n_g_state on qrtz_triggers(SCHED_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX idx_qrtz_t_next_fire_time on qrtz_triggers(SCHED_NAME,NEXT_FIRE_TIME);
CREATE INDEX idx_qrtz_t_nft_st on qrtz_triggers(SCHED_NAME,TRIGGER_STATE,NEXT_FIRE_TIME);
CREATE INDEX idx_qrtz_t_nft_misfire on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME);
CREATE INDEX idx_qrtz_t_nft_st_misfire on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_STATE);
CREATE INDEX idx_qrtz_t_nft_st_misfire_grp on qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX idx_qrtz_ft_trig_inst_name on qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME);
CREATE INDEX idx_qrtz_ft_inst_job_req_rcvry on qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME,REQUESTS_RECOVERY);
CREATE INDEX idx_qrtz_ft_j_g on qrtz_fired_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX idx_qrtz_ft_jg on qrtz_fired_triggers(SCHED_NAME,JOB_GROUP);
CREATE INDEX idx_qrtz_ft_t_g on qrtz_fired_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP);
CREATE INDEX idx_qrtz_ft_tg on qrtz_fired_triggers(SCHED_NAME,TRIGGER_GROUP);
