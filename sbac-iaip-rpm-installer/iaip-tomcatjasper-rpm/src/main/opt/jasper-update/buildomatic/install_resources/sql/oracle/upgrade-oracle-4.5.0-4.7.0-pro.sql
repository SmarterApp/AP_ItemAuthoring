--
-- add resourceType column to jiresource table, popolate with data and create index
--

ALTER TABLE JIResource ADD ( resourceType nvarchar2(255) );

UPDATE JIResource
SET resourceType = 
(
SELECT substr ( rtype , 6 ) res FROM (
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
) GROUP BY id 
) data WHERE data.id = JIResource.id
);
ALTER TABLE JIResource MODIFY ( resourceType nvarchar2(255) NOT NULL );
CREATE INDEX resource_type_index ON JIResource (resourceType);



--
-- alter tables and add data to columns if required
--

-- add and populate creation_date column to JIReportJob table
ALTER TABLE JIReportJob ADD ( creation_date timestamp );
UPDATE JIReportJob SET creation_date = CURRENT_DATE;

-- add alert column to JIReportJob table
ALTER TABLE JIReportJob ADD ( alert number(19,0) );

-- add data_snapshot_id column to JIReportUnit table
ALTER TABLE JIReportUnit ADD ( data_snapshot_id number(19,0) );

-- add and populate new columns for JIReportJobMail table 
ALTER TABLE JIReportJobMail ADD ( message_text_when_job_fails nvarchar2(2000) );
ALTER TABLE JIReportJobMail ADD ( inc_stktrc_when_job_fails number(1,0));
ALTER TABLE JIReportJobMail ADD ( skip_notif_when_job_fails number(1,0));
UPDATE JIReportJobMail SET inc_stktrc_when_job_fails = 0;
UPDATE JIReportJobMail SET skip_notif_when_job_fails = 0;
ALTER TABLE JIReportJobMail MODIFY ( inc_stktrc_when_job_fails number(1,0) NOT NULL );
ALTER TABLE JIReportJobMail MODIFY ( skip_notif_when_job_fails number(1,0) NOT NULL );


-- add and populate new columns for JIReportJobRepoDest table 
ALTER TABLE JIReportJobRepoDest ADD ( save_to_repository number(1,0));
ALTER TABLE JIReportJobRepoDest ADD ( using_def_rpt_opt_folder_uri number(1,0));
ALTER TABLE JIReportJobRepoDest ADD ( output_local_folder nvarchar2(250) );
ALTER TABLE JIReportJobRepoDest ADD ( user_name nvarchar2(50) );
ALTER TABLE JIReportJobRepoDest ADD ( password nvarchar2(50) );
ALTER TABLE JIReportJobRepoDest ADD ( server_name nvarchar2(150) );
ALTER TABLE JIReportJobRepoDest ADD ( folder_path nvarchar2(250) );
ALTER TABLE JIReportJobRepoDest MODIFY ( folder_uri nvarchar2(250) NULL );
UPDATE JIReportJobRepoDest SET save_to_repository = 1;
UPDATE JIReportJobRepoDest SET using_def_rpt_opt_folder_uri = 0;
ALTER TABLE JIReportJobRepoDest MODIFY ( save_to_repository number(1,0) NOT NULL );
ALTER TABLE JIReportJobRepoDest MODIFY ( using_def_rpt_opt_folder_uri number(1,0) NOT NULL );

-- add new columns for JIReportJobTrigger table 
ALTER TABLE JIReportJobTrigger ADD ( calendar_name nvarchar2(50) );
ALTER TABLE JIReportJobTrigger ADD ( misfire_instruction number(10,0));
UPDATE JIReportJobTrigger SET misfire_instruction = 0;
ALTER TABLE JIReportJobTrigger MODIFY ( misfire_instruction number(10,0) NOT NULL );


--
-- ReportJob tables
--

    create table JIFTPInfoProperties (
        repodest_id number(19,0) not null,
        property_value nvarchar2(250),
        property_name nvarchar2(100) not null,
        primary key (repodest_id, property_name)
    );

    create table JIReportAlertToAddress (
        alert_id number(19,0) not null,
        to_address nvarchar2(100) not null,
        to_address_idx number(10,0) not null,
        primary key (alert_id, to_address_idx)
    );

    create table JIReportJobAlert (
        id number(19,0) not null,
        version number(10,0) not null,
        recipient number(3,0) not null,
        subject nvarchar2(100),
        message_text nvarchar2(2000),
        message_text_when_job_fails nvarchar2(2000),
        job_state number(3,0) not null,
        including_stack_trace number(1,0) not null,
        including_report_job_info number(1,0) not null,
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
        id number(19,0) not null,
        version number(10,0) not null,
        snapshot_date timestamp,
        contents_id number(19,0) not null,
        primary key (id)
    );

    create table JIDataSnapshotContents (
        id number(19,0) not null,
        data blob not null,
        primary key (id)
    );

    create table JIDataSnapshotParameter (
        id number(19,0) not null,
        parameter_value blob,
        parameter_name nvarchar2(100) not null,
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
        id number(19,0) not null,
        adhocStateId number(19,0),
        reportDataSource number(19,0),
        promptcontrols number(1,0),
        controlslayout number(3,0),
        controlrenderer nvarchar2(100),
        primary key (id)
    );

    create table JIAdhocDataViewInputControl (
        adhoc_data_view_id number(19,0) not null,
        input_control_id number(19,0) not null,
        control_index number(10,0) not null,
        primary key (adhoc_data_view_id, control_index)
    );

    create table JIAdhocDataViewResource (
        adhoc_data_view_id number(19,0) not null,
        resource_id number(19,0) not null,
        resource_index number(10,0) not null,
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
