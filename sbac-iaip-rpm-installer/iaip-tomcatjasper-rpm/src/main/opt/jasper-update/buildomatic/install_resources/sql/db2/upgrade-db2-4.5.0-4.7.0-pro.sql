--
-- add resourceType column to jiresource table, popolate with data and create index
--

ALTER TABLE "JIRESOURCE" ADD COLUMN resourceType varchar(255) NOT NULL DEFAULT ' ';

UPDATE "JIRESOURCE" as a
SET resourceType = 
(
        SELECT substr(rtype,6) FROM (
                SELECT id, min(resourceType) rtype FROM (
      SELECT id, 'B001_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.BeanReportDataSource' AS resourceType FROM "JIBEANDATASOURCE"
UNION SELECT id, 'B002_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.CustomReportDataSource' AS resourceType FROM "JICUSTOMDATASOURCE"
UNION SELECT id, 'B003_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.JdbcReportDataSource' AS resourceType FROM "JIJDBCDATASOURCE"
UNION SELECT id, 'B004_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.JndiJdbcReportDataSource' AS resourceType FROM "JIJNDIJDBCDATASOURCE"
UNION SELECT id, 'B005_com.jaspersoft.commons.semantic.datasource.SemanticLayerDataSource' AS resourceType FROM "JIDOMAINDATASOURCE"
UNION SELECT id, 'B011_com.jaspersoft.ji.ja.security.domain.SecureMondrianConnection' AS resourceType FROM "JIMONDRIANCONNECTION"
UNION SELECT id, 'B012_com.jaspersoft.jasperserver.api.metadata.olap.domain.XMLAConnection' AS resourceType FROM "JIXMLACONNECTION"
UNION SELECT id, 'B021_com.jaspersoft.ji.adhoc.AdhocReportUnit' AS resourceType FROM "JIADHOCREPORTUNIT"
UNION SELECT id, 'B022_com.jaspersoft.commons.semantic.DataDefinerUnit' AS resourceType FROM "JIDATADEFINERUNIT"
UNION SELECT id, 'C011_com.jaspersoft.jasperserver.api.metadata.common.domain.ContentResource' AS resourceType FROM "JICONTENTRESOURCE"
UNION SELECT id, 'C012_com.jaspersoft.ji.adhoc.DashboardResource' AS resourceType FROM "JIDASHBOARD"
UNION SELECT id, 'C013_com.jaspersoft.jasperserver.api.metadata.common.domain.DataType' AS resourceType FROM "JIDATATYPE"
UNION SELECT id, 'C014_com.jaspersoft.jasperserver.api.metadata.common.domain.FileResource' AS resourceType FROM "JIFILERESOURCE"
UNION SELECT id, 'C015_com.jaspersoft.jasperserver.api.metadata.common.domain.InputControl' AS resourceType FROM "JIINPUTCONTROL"
UNION SELECT id, 'C016_com.jaspersoft.jasperserver.api.metadata.common.domain.ListOfValues' AS resourceType FROM "JILISTOFVALUES"
UNION SELECT id, 'C017_com.jaspersoft.jasperserver.api.metadata.olap.domain.MondrianXMLADefinition' AS resourceType FROM "JIMONDRIANXMLADEFINITION"
UNION SELECT id, 'C018_com.jaspersoft.jasperserver.api.metadata.olap.domain.OlapUnit' AS resourceType FROM "JIOLAPUNIT"
UNION SELECT id, 'C019_com.jaspersoft.jasperserver.api.metadata.common.domain.Query' AS resourceType FROM "JIQUERY"
UNION SELECT id, 'C020_com.jaspersoft.ji.report.options.metadata.ReportOptions' AS resourceType FROM "JIREPORTOPTIONS"
UNION SELECT id, 'C021_com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.ReportUnit' AS resourceType FROM "JIREPORTUNIT"
                ) GROUP BY id
        ) as b  WHERE b.id = a.id
);

CREATE INDEX resource_type_index ON JIResource (resourceType);


--
-- alter tables and add data to columns if required
--

-- add and populate creation_date column to JIReportJob table
ALTER TABLE JIReportJob ADD COLUMN creation_date timestamp;
UPDATE JIReportJob SET creation_date = CURRENT_DATE;

-- add alert column to JIReportJob table
ALTER TABLE JIReportJob ADD COLUMN alert BIGINT;

-- add data_snapshot_id column to JIReportUnit table
ALTER TABLE JIReportUnit ADD COLUMN data_snapshot_id BIGINT;

-- add and populate new columns for JIReportJobMail table 
ALTER TABLE JIReportJobMail ADD COLUMN message_text_when_job_fails varchar(2000);
ALTER TABLE JIReportJobMail ADD COLUMN inc_stktrc_when_job_fails smallint NOT NULL DEFAULT;
ALTER TABLE JIReportJobMail ADD COLUMN skip_notif_when_job_fails smallint NOT NULL DEFAULT;
UPDATE JIReportJobMail SET inc_stktrc_when_job_fails = 0;
UPDATE JIReportJobMail SET skip_notif_when_job_fails = 0;

-- add and populate new columns for JIReportJobRepoDest table 
ALTER TABLE JIReportJobRepoDest ADD COLUMN save_to_repository smallint NOT NULL DEFAULT;
ALTER TABLE JIReportJobRepoDest ADD COLUMN using_def_rpt_opt_folder_uri smallint NOT NULL DEFAULT;
ALTER TABLE JIReportJobRepoDest ADD COLUMN output_local_folder varchar(250);
ALTER TABLE JIReportJobRepoDest ADD COLUMN user_name varchar(50);
ALTER TABLE JIReportJobRepoDest ADD COLUMN password varchar(50);
ALTER TABLE JIReportJobRepoDest ADD COLUMN server_name varchar(150);
ALTER TABLE JIReportJobRepoDest ADD COLUMN folder_path varchar(250);
UPDATE JIReportJobRepoDest SET save_to_repository = 1;
UPDATE JIReportJobRepoDest SET using_def_rpt_opt_folder_uri = 0;

-- add new columns for JIReportJobTrigger table 
ALTER TABLE JIReportJobTrigger ADD COLUMN calendar_name varchar(50);
ALTER TABLE JIReportJobTrigger ADD COLUMN misfire_instruction integer NOT NULL DEFAULT;
UPDATE JIReportJobTrigger SET misfire_instruction = 0;


--
-- ReportJob tables
--

    create table JIFTPInfoProperties (
        repodest_id BIGINT not null,
        property_value varchar(250),
        property_name varchar(100) not null,
        primary key (repodest_id, property_name)
    );

    create table JIReportAlertToAddress (
        alert_id BIGINT not null,
        to_address varchar(100) not null,
        to_address_idx Integer not null,
        primary key (alert_id, to_address_idx)
    );

    create table JIReportJobAlert (
        id bigint generated by default as identity,
        version Integer not null,
        recipient Smallint not null,
        subject varchar(100),
        message_text varchar(2000),
        message_text_when_job_fails varchar(2000),
        job_state Smallint not null,
        including_stack_trace Smallint not null,
        including_report_job_info Smallint not null,
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
        id BIGINT not null,
        version Integer not null,
        snapshot_date timestamp,
        contents_id BIGINT not null,
        primary key (id)
    );

    create table JIDataSnapshotContents (
        id BIGINT not null,
        data blob not null,
        primary key (id)
    );

    create table JIDataSnapshotParameter (
        id BIGINT not null,
        parameter_value blob(20971520),
        parameter_name varchar(100) not null,
        primary key (id, parameter_name)
    );

    alter table JIDataSnapshotParameter
        add constraint id_fk_idx
        foreign key (id)
        references JIDataSnapshot;

--
-- Adhoc tables
--

   create table JIAdhocDataView (
        id BIGINT not null,
        adhocStateId BIGINT,
        reportDataSource BIGINT,
        promptcontrols Smallint,
        controlslayout Smallint,
        controlrenderer varchar(100),
        primary key (id)
    );

    create table JIAdhocDataViewInputControl (
        adhoc_data_view_id BIGINT not null,
        input_control_id BIGINT not null,
        control_index Integer not null,
        primary key (adhoc_data_view_id, control_index)
    );

    create table JIAdhocDataViewResource (
        adhoc_data_view_id BIGINT not null,
        resource_id BIGINT not null,
        resource_index Integer not null,
        primary key (adhoc_data_view_id, resource_index)
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
