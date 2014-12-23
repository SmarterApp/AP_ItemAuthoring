
    create table JIAccessEvent (
        id numeric(19,0) identity not null,
        user_id numeric(19,0) not null,
        event_date datetime not null,
        resource_id numeric(19,0) not null,
        updating tinyint not null,
        primary key (id)
    );

    create table JIAdhocChartMeasure (
        id numeric(19,0) not null,
        name nvarchar(255) not null,
        label nvarchar(255) null,
        width int null,
        jiFunction nvarchar(255) null,
        type nvarchar(255) null,
        mask nvarchar(255) null,
        functionMask nvarchar(255) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIAdhocColumn (
        id numeric(19,0) not null,
        name nvarchar(255) not null,
        label nvarchar(255) null,
        width int null,
        jiFunction nvarchar(255) null,
        type nvarchar(255) null,
        mask nvarchar(255) null,
        functionMask nvarchar(255) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIAdhocDataView (
        id numeric(19,0) not null,
        adhocStateId numeric(19,0) null,
        reportDataSource numeric(19,0) null,
        promptcontrols tinyint null,
        controlslayout tinyint null,
        controlrenderer nvarchar(100) null,
        primary key (id)
    );

    create table JIAdhocDataViewInputControl (
        adhoc_data_view_id numeric(19,0) not null,
        input_control_id numeric(19,0) not null,
        control_index int not null,
        primary key (adhoc_data_view_id, control_index)
    );

    create table JIAdhocDataViewResource (
        adhoc_data_view_id numeric(19,0) not null,
        resource_id numeric(19,0) not null,
        resource_index int not null,
        primary key (adhoc_data_view_id, resource_index)
    );

    create table JIAdhocGroup (
        id numeric(19,0) not null,
        name nvarchar(255) not null,
        label nvarchar(255) null,
        type nvarchar(255) null,
        mask nvarchar(255) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIAdhocReportUnit (
        id numeric(19,0) not null,
        adhocStateId numeric(19,0) null,
        primary key (id)
    );

    create table JIAdhocState (
        id numeric(19,0) identity not null,
        type nvarchar(255) not null,
        theme nvarchar(255) null,
        title nvarchar(255) null,
        pageOrientation nvarchar(255) null,
        paperSize nvarchar(255) null,
        maxRows int null,
        summaryLabel nvarchar(255) null,
        group_name nvarchar(255) null,
        group_label nvarchar(255) null,
        group_type nvarchar(255) null,
        group_mask nvarchar(255) null,
        primary key (id)
    );

    create table JIAdhocStateProperty (
        state_id numeric(19,0) not null,
        value nvarchar(1000) null,
        name nvarchar(100) not null,
        primary key (state_id, name)
    );

    create table JIAdhocTableSortField (
        id numeric(19,0) not null,
        fieldName nvarchar(255) not null,
        ascending tinyint null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIAdhocXTabColumnGroup (
        id numeric(19,0) not null,
        name nvarchar(255) not null,
        label nvarchar(255) null,
        type nvarchar(255) null,
        categorizer nvarchar(1000) null,
        fieldName nvarchar(255) null,
        fieldType nvarchar(255) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIAdhocXTabMeasure (
        id numeric(19,0) not null,
        name nvarchar(255) not null,
        label nvarchar(255) null,
        width int null,
        jiFunction nvarchar(255) null,
        type nvarchar(255) null,
        mask nvarchar(255) null,
        functionMask nvarchar(255) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIAdhocXTabRowGroup (
        id numeric(19,0) not null,
        name nvarchar(255) not null,
        label nvarchar(255) null,
        type nvarchar(255) null,
        categorizer nvarchar(1000) null,
        fieldName nvarchar(255) null,
        fieldType nvarchar(255) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIAuditEvent (
        id numeric(19,0) identity not null,
        username nvarchar(100) null,
        tenant_id nvarchar(100) null,
        event_date datetime not null,
        resource_uri nvarchar(250) null,
        resource_type nvarchar(250) null,
        event_type nvarchar(100) not null,
        request_type nvarchar(100) not null,
        primary key (id)
    );

    create table JIAuditEventArchive (
        id numeric(19,0) identity not null,
        username nvarchar(100) null,
        tenant_id nvarchar(100) null,
        event_date datetime not null,
        resource_uri nvarchar(250) null,
        resource_type nvarchar(250) null,
        event_type nvarchar(100) not null,
        request_type nvarchar(100) not null,
        primary key (id)
    );

    create table JIAuditEventProperty (
        id numeric(19,0) identity not null,
        property_type nvarchar(100) not null,
        value nvarchar(250) null,
        clob_value nvarchar(max) null,
        audit_event_id numeric(19,0) not null,
        primary key (id)
    );

    create table JIAuditEventPropertyArchive (
        id numeric(19,0) identity not null,
        property_type nvarchar(100) not null,
        value nvarchar(250) null,
        clob_value nvarchar(max) null,
        audit_event_id numeric(19,0) not null,
        primary key (id)
    );

    create table JIBeanDatasource (
        id numeric(19,0) not null,
        beanName nvarchar(100) not null,
        beanMethod nvarchar(100) null,
        primary key (id)
    );

    create table JIContentResource (
        id numeric(19,0) not null,
        data varbinary(max) null,
        file_type nvarchar(20) null,
        primary key (id)
    );

    create table JICustomDatasource (
        id numeric(19,0) not null,
        serviceClass nvarchar(250) not null,
        primary key (id)
    );

    create table JICustomDatasourceProperty (
        ds_id numeric(19,0) not null,
        value nvarchar(1000) null,
        name nvarchar(100) not null,
        primary key (ds_id, name)
    );

    create table JIDashboard (
        id numeric(19,0) not null,
        adhocStateId numeric(19,0) null,
        primary key (id)
    );

    create table JIDashboardFrameProperty (
        id numeric(19,0) not null,
        frameName nvarchar(255) not null,
        frameClassName nvarchar(255) not null,
        propertyName nvarchar(255) not null,
        propertyValue nvarchar(1000) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JIDashboardResource (
        dashboard_id numeric(19,0) not null,
        resource_id numeric(19,0) not null,
        resource_index int not null,
        primary key (dashboard_id, resource_index)
    );

    create table JIDataDefinerUnit (
        id numeric(19,0) not null,
        primary key (id)
    );

    create table JIDataSnapshot (
        id numeric(19,0) identity not null,
        version int not null,
        snapshot_date datetime null,
        contents_id numeric(19,0) not null,
        primary key (id)
    );

    create table JIDataSnapshotContents (
        id numeric(19,0) identity not null,
        data varbinary(max) not null,
        primary key (id)
    );

    create table JIDataSnapshotParameter (
        id numeric(19,0) not null,
        parameter_value varbinary(max) null,
        parameter_name nvarchar(100) not null,
        primary key (id, parameter_name)
    );

    create table JIDataType (
        id numeric(19,0) not null,
        type tinyint null,
        maxLength int null,
        decimals int null,
        regularExpr nvarchar(255) null,
        minValue varbinary(255) null,
        max_value varbinary(255) null,
        strictMin tinyint null,
        strictMax tinyint null,
        primary key (id)
    );

    create table JIDomainDatasource (
        id numeric(19,0) not null,
        schema_id numeric(19,0) not null,
        security_id numeric(19,0) null,
        primary key (id)
    );

    create table JIDomainDatasourceBundle (
        slds_id numeric(19,0) not null,
        locale nvarchar(20) null,
        bundle_id numeric(19,0) not null,
        idx int not null,
        primary key (slds_id, idx)
    );

    create table JIDomainDatasourceDSRef (
        slds_id numeric(19,0) not null,
        ref_id numeric(19,0) not null,
        alias nvarchar(100) not null,
        primary key (slds_id, alias)
    );

    create table JIFTPInfoProperties (
        repodest_id numeric(19,0) not null,
        property_value nvarchar(250) null,
        property_name nvarchar(100) not null,
        primary key (repodest_id, property_name)
    );

    create table JIFileResource (
        id numeric(19,0) not null,
        data varbinary(max) null,
        file_type nvarchar(20) null,
        reference numeric(19,0) null,
        primary key (id)
    );

    create table JIInputControl (
        id numeric(19,0) not null,
        type tinyint null,
        mandatory tinyint null,
        readOnly tinyint null,
        visible tinyint null,
        data_type numeric(19,0) null,
        list_of_values numeric(19,0) null,
        list_query numeric(19,0) null,
        query_value_column nvarchar(200) null,
        defaultValue varbinary(255) null,
        primary key (id)
    );

    create table JIInputControlQueryColumn (
        input_control_id numeric(19,0) not null,
        query_column nvarchar(200) not null,
        column_index int not null,
        primary key (input_control_id, column_index)
    );

    create table JIJNDIJdbcDatasource (
        id numeric(19,0) not null,
        jndiName nvarchar(100) not null,
        timezone nvarchar(100) null,
        primary key (id)
    );

    create table JIJdbcDatasource (
        id numeric(19,0) not null,
        driver nvarchar(100) not null,
        password nvarchar(100) null,
        connectionUrl nvarchar(500) null,
        username nvarchar(100) null,
        timezone nvarchar(100) null,
        primary key (id)
    );

    create table JIAwsDatasource (
        id numeric(19,0) not null,
        accessKey nvarchar(100),
        secretKey nvarchar(100),
        roleARN nvarchar(100),
        region nvarchar(100) not null,
        dbName nvarchar(100) not null,
        dbInstanceIdentifier nvarchar(100) not null,
        dbService nvarchar(100) not null,
        primary key (id)
    );

    create table JIListOfValues (
        id numeric(19,0) not null,
        primary key (id)
    );

    create table JIListOfValuesItem (
        id numeric(19,0) not null,
        label nvarchar(255) null,
        value varbinary(255) null,
        idx int not null,
        primary key (id, idx)
    );

    create table JILogEvent (
        id numeric(19,0) identity not null,
        occurrence_date datetime not null,
        event_type tinyint not null,
        component nvarchar(100) null,
        message nvarchar(250) not null,
        resource_uri nvarchar(250) null,
        event_text nvarchar(max) null,
        event_data varbinary(max) null,
        event_state tinyint null,
        userId numeric(19,0) null,
        primary key (id)
    );

    create table JIMondrianConnection (
        id numeric(19,0) not null,
        reportDataSource numeric(19,0) null,
        mondrianSchema numeric(19,0) null,
        primary key (id)
    );

    create table JIMondrianConnectionGrant (
        mondrianConnectionId numeric(19,0) not null,
        accessGrant numeric(19,0) not null,
        grantIndex int not null,
        primary key (mondrianConnectionId, grantIndex)
    );

    create table JIMondrianXMLADefinition (
        id numeric(19,0) not null,
        catalog nvarchar(100) not null,
        mondrianConnection numeric(19,0) null,
        primary key (id)
    );

    create table JIObjectPermission (
        id numeric(19,0) identity not null,
        uri nvarchar(250) not null,
        recipientobjectclass nvarchar(250) null,
        recipientobjectid numeric(19,0) null,
        permissionMask int not null,
        primary key (id)
    );

    create table JIOlapClientConnection (
        id numeric(19,0) not null,
        primary key (id)
    );

    create table JIOlapUnit (
        id numeric(19,0) not null,
        olapClientConnection numeric(19,0) null,
        mdx_query nvarchar(max) not null,
        view_options varbinary(max) null,
        primary key (id)
    );

    create table JIProfileAttribute (
        id numeric(19,0) identity not null,
        attrName nvarchar(255) not null,
        attrValue nvarchar(255) not null,
        principalobjectclass nvarchar(255) not null,
        principalobjectid numeric(19,0) not null,
        primary key (id)
    );

    create table JIQuery (
        id numeric(19,0) not null,
        dataSource numeric(19,0) null,
        query_language nvarchar(40) not null,
        sql_query nvarchar(max) not null,
        primary key (id)
    );

    create table JIReportAlertToAddress (
        alert_id numeric(19,0) not null,
        to_address nvarchar(100) not null,
        to_address_idx int not null,
        primary key (alert_id, to_address_idx)
    );

    create table JIReportJob (
        id numeric(19,0) identity not null,
        version int not null,
        owner numeric(19,0) not null,
        label nvarchar(100) not null,
        description nvarchar(2000) null,
        creation_date datetime null,
        report_unit_uri nvarchar(250) not null,
        job_trigger numeric(19,0) not null,
        base_output_name nvarchar(100) not null,
        output_locale nvarchar(20) null,
        content_destination numeric(19,0) null,
        mail_notification numeric(19,0) null,
        alert numeric(19,0) null,
        primary key (id)
    );

    create table JIReportJobAlert (
        id numeric(19,0) identity not null,
        version int not null,
        recipient tinyint not null,
        subject nvarchar(100) null,
        message_text nvarchar(2000) null,
        message_text_when_job_fails nvarchar(2000) null,
        job_state tinyint not null,
        including_stack_trace tinyint not null,
        including_report_job_info tinyint not null,
        primary key (id)
    );

    create table JIReportJobCalendarTrigger (
        id numeric(19,0) not null,
        minutes nvarchar(200) not null,
        hours nvarchar(80) not null,
        days_type tinyint not null,
        week_days nvarchar(20) null,
        month_days nvarchar(100) null,
        months nvarchar(40) not null,
        primary key (id)
    );

    create table JIReportJobMail (
        id numeric(19,0) identity not null,
        version int not null,
        subject nvarchar(100) not null,
        message nvarchar(2000) null,
        send_type tinyint not null,
        skip_empty tinyint not null,
        message_text_when_job_fails nvarchar(2000) null,
        inc_stktrc_when_job_fails tinyint not null,
        skip_notif_when_job_fails tinyint not null,
        primary key (id)
    );

    create table JIReportJobMailRecipient (
        destination_id numeric(19,0) not null,
        recipient_type tinyint not null,
        address nvarchar(100) not null,
        recipient_idx int not null,
        primary key (destination_id, recipient_idx)
    );

    create table JIReportJobOutputFormat (
        report_job_id numeric(19,0) not null,
        output_format tinyint not null,
        primary key (report_job_id, output_format)
    );

    create table JIReportJobParameter (
        job_id numeric(19,0) not null,
        parameter_value varbinary(max) null,
        parameter_name nvarchar(100) not null,
        primary key (job_id, parameter_name)
    );

    create table JIReportJobRepoDest (
        id numeric(19,0) identity not null,
        version int not null,
        folder_uri nvarchar(250) null,
        sequential_filenames tinyint not null,
        overwrite_files tinyint not null,
        save_to_repository tinyint not null,
        output_description nvarchar(250) null,
        timestamp_pattern nvarchar(250) null,
        using_def_rpt_opt_folder_uri tinyint not null,
        output_local_folder nvarchar(250) null,
        user_name nvarchar(50) null,
        password nvarchar(50) null,
        server_name nvarchar(150) null,
        folder_path nvarchar(250) null,
        primary key (id)
    );

    create table JIReportJobSimpleTrigger (
        id numeric(19,0) not null,
        occurrence_count int not null,
        recurrence_interval int null,
        recurrence_interval_unit tinyint null,
        primary key (id)
    );

    create table JIReportJobTrigger (
        id numeric(19,0) identity not null,
        version int not null,
        timezone nvarchar(40) null,
        start_type tinyint not null,
        start_date datetime null,
        end_date datetime null,
        calendar_name nvarchar(50) null,
        misfire_instruction int not null,
        primary key (id)
    );

    create table JIReportMonitoringFact (
        id numeric(19,0) identity not null,
        date_year smallint not null,
        date_month tinyint not null,
        date_day tinyint not null,
        time_hour tinyint not null,
        time_minute tinyint not null,
        event_context nvarchar(255) not null,
        user_organization nvarchar(255) null,
        user_name nvarchar(255) null,
        event_type nvarchar(255) not null,
        report_uri nvarchar(255) null,
        editing_action nvarchar(255) null,
        query_execution_time int not null,
        report_rendering_time int not null,
        total_report_execution_time int not null,
        time_stamp datetime not null,
        primary key (id)
    );

    create table JIReportOptions (
        id numeric(19,0) not null,
        options_name nvarchar(210) not null,
        report_id numeric(19,0) not null,
        primary key (id)
    );

    create table JIReportOptionsInput (
        options_id numeric(19,0) not null,
        input_value varbinary(1000) null,
        input_name nvarchar(100) not null,
        primary key (options_id, input_name)
    );

    create table JIReportUnit (
        id numeric(19,0) not null,
        reportDataSource numeric(19,0) null,
        query numeric(19,0) null,
        mainReport numeric(19,0) null,
        controlrenderer nvarchar(100) null,
        reportrenderer nvarchar(100) null,
        promptcontrols tinyint null,
        controlslayout tinyint null,
        data_snapshot_id numeric(19,0) null,
        primary key (id)
    );

    create table JIReportUnitInputControl (
        report_unit_id numeric(19,0) not null,
        input_control_id numeric(19,0) not null,
        control_index int not null,
        primary key (report_unit_id, control_index)
    );

    create table JIReportUnitResource (
        report_unit_id numeric(19,0) not null,
        resource_id numeric(19,0) not null,
        resource_index int not null,
        primary key (report_unit_id, resource_index)
    );

    create table JIRepositoryCache (
        id numeric(19,0) identity not null,
        uri nvarchar(250) not null,
        cache_name nvarchar(20) not null,
        data varbinary(max) null,
        version int not null,
        version_date datetime not null,
        item_reference numeric(19,0) null,
        primary key (id),
        unique (uri, cache_name)
    );

    create table JIResource (
        id numeric(19,0) identity not null,
        version int not null,
        name nvarchar(100) not null,
        parent_folder numeric(19,0) not null,
        childrenFolder numeric(19,0) null,
        label nvarchar(100) not null,
        description nvarchar(250) null,
        resourceType nvarchar(255) not null,
        creation_date datetime not null,
        update_date datetime not null,
        primary key (id),
        unique (name, parent_folder)
    );

    create table JIResourceFolder (
        id numeric(19,0) identity not null,
        version int not null,
        uri nvarchar(250) not null,
        hidden tinyint null,
        name nvarchar(100) not null,
        label nvarchar(100) not null,
        description nvarchar(250) null,
        parent_folder numeric(19,0) null,
        creation_date datetime not null,
        update_date datetime not null,
        primary key (id),
        unique (uri)
    );

    create table JIRole (
        id numeric(19,0) identity not null,
        rolename nvarchar(100) not null,
        tenantId numeric(19,0) not null,
        externallyDefined tinyint null,
        primary key (id),
        unique (rolename, tenantId)
    );

    create table JITenant (
        id numeric(19,0) identity not null,
        tenantId nvarchar(100) not null,
        tenantAlias nvarchar(100) not null,
        parentId numeric(19,0) null,
        tenantName nvarchar(100) not null,
        tenantDesc nvarchar(250) null,
        tenantNote nvarchar(250) null,
        tenantUri nvarchar(250) not null,
        tenantFolderUri nvarchar(250) not null,
        theme nvarchar(250) null,
        primary key (id),
        unique (tenantId)
    );

    create table JIUser (
        id numeric(19,0) identity not null,
        username nvarchar(100) not null,
        tenantId numeric(19,0) not null,
        fullname nvarchar(100) not null,
        emailAddress nvarchar(100) null,
        password nvarchar(100) null,
        externallyDefined tinyint null,
        enabled tinyint null,
        previousPasswordChangeTime datetime null,
        primary key (id),
        unique (username, tenantId)
    );

    create table JIUserRole (
        roleId numeric(19,0) not null,
        userId numeric(19,0) not null,
        primary key (userId, roleId)
    );

    create table JIVirtualDataSourceUriMap (
        virtualDS_id numeric(19,0) not null,
        resource_id numeric(19,0) not null,
        data_source_name nvarchar(100) not null,
        primary key (virtualDS_id, data_source_name)
    );

    create table JIVirtualDatasource (
        id numeric(19,0) not null,
        timezone nvarchar(100) null,
        primary key (id)
    );

    create table JIXMLAConnection (
        id numeric(19,0) not null,
        catalog nvarchar(100) not null,
        username nvarchar(100) not null,
        password nvarchar(100) not null,
        datasource nvarchar(100) not null,
        uri nvarchar(100) not null,
        primary key (id)
    );

    create table ProfilingRecord (
        id numeric(19,0) identity not null,
        parent_id numeric(19,0) null,
        duration_ms numeric(19,0) null,
        description nvarchar(1000) null,
        begin_date datetime not null,
        cache_hit tinyint null,
        agg_hit tinyint null,
        sql_query tinyint null,
        mdx_query tinyint null,
        begin_year int not null,
        begin_month int not null,
        begin_day int not null,
        begin_hour int not null,
        begin_min int not null,
        begin_sec int not null,
        begin_ms int not null,
        primary key (id)
    );

    create index access_date_index on JIAccessEvent (event_date);

    create index access_upd_index on JIAccessEvent (updating);

    create index access_user_index on JIAccessEvent (user_id);

    create index access_res_index on JIAccessEvent (resource_id);

    alter table JIAccessEvent 
        add constraint FK47FB3CD732282198 
        foreign key (user_id) 
        references JIUser;

    alter table JIAccessEvent 
        add constraint FK47FB3CD7F254B53E 
        foreign key (resource_id) 
        references JIResource
        on delete cascade;

    alter table JIAdhocChartMeasure 
        add constraint FK89D1A3FAB0A3C8CB 
        foreign key (id) 
        references JIAdhocState;

    alter table JIAdhocColumn 
        add constraint FK9265D330EC885ADB 
        foreign key (id) 
        references JIAdhocState;

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

    alter table JIAdhocGroup 
        add constraint FK704D9365EC885ADB 
        foreign key (id) 
        references JIAdhocState;

    alter table JIAdhocReportUnit 
        add constraint FK68AE6BB2981B13F0 
        foreign key (id) 
        references JIReportUnit;

    alter table JIAdhocReportUnit 
        add constraint FK68AE6BB231211827 
        foreign key (adhocStateId) 
        references JIAdhocState;

    alter table JIAdhocStateProperty 
        add constraint FK2C7E3C6C298B519D 
        foreign key (state_id) 
        references JIAdhocState;

    alter table JIAdhocTableSortField 
        add constraint FK1AF05FA8EC885ADB 
        foreign key (id) 
        references JIAdhocState;

    alter table JIAdhocXTabColumnGroup 
        add constraint FK336E71F262231DA 
        foreign key (id) 
        references JIAdhocState;

    alter table JIAdhocXTabMeasure 
        add constraint FK3CF53B0762231DA 
        foreign key (id) 
        references JIAdhocState;

    alter table JIAdhocXTabRowGroup 
        add constraint FK9D33843C62231DA 
        foreign key (id) 
        references JIAdhocState;

    create index res_type_index on JIAuditEvent (resource_type);

    create index event_type_index on JIAuditEvent (event_type);

    create index event_date_index on JIAuditEvent (event_date);

    create index tenant_id_index on JIAuditEvent (tenant_id);

    create index request_type_index on JIAuditEvent (request_type);

    create index resource_uri_index on JIAuditEvent (resource_uri);

    create index username_index on JIAuditEvent (username);

    alter table JIAuditEventProperty 
        add constraint FK3429FE136F667020 
        foreign key (audit_event_id) 
        references JIAuditEvent;

    alter table JIAuditEventPropertyArchive 
        add constraint FKD2940F2F637AC28A 
        foreign key (audit_event_id) 
        references JIAuditEventArchive;

    alter table JIBeanDatasource 
        add constraint FK674BF34A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIContentResource 
        add constraint FKE466FC68A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JICustomDatasource 
        add constraint FK2BBCEDF5A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JICustomDatasourceProperty 
        add constraint FKB8A66AEA858A89D1 
        foreign key (ds_id) 
        references JICustomDatasource;

    alter table JIDashboard 
        add constraint FKEC09F815A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIDashboard 
        add constraint FKEC09F81531211827 
        foreign key (adhocStateId) 
        references JIAdhocState;

    alter table JIDashboardFrameProperty 
        add constraint FK679EF04DFA08F0B4 
        foreign key (id) 
        references JIAdhocState;

    alter table JIDashboardResource 
        add constraint FK37B53B43326276AC 
        foreign key (dashboard_id) 
        references JIDashboard;

    alter table JIDashboardResource 
        add constraint FK37B53B43F254B53E 
        foreign key (resource_id) 
        references JIResource;

    alter table JIDataDefinerUnit 
        add constraint FK1EC11AF2981B13F0 
        foreign key (id) 
        references JIReportUnit;

    alter table JIDataSnapshotParameter 
        add constraint id_fk_idx 
        foreign key (id) 
        references JIDataSnapshot;

    alter table JIDataType 
        add constraint FK533BCC63A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIDomainDatasource 
        add constraint FK59F8EB88A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIDomainDatasource 
        add constraint FK59F8EB88992A3868 
        foreign key (security_id) 
        references JIFileResource;

    alter table JIDomainDatasource 
        add constraint FK59F8EB8833A6D267 
        foreign key (schema_id) 
        references JIFileResource;

    alter table JIDomainDatasourceBundle 
        add constraint FKE9F0422AE494DFE6 
        foreign key (bundle_id) 
        references JIFileResource;

    alter table JIDomainDatasourceBundle 
        add constraint FKE9F0422ACB906E03 
        foreign key (slds_id) 
        references JIDomainDatasource;

    alter table JIDomainDatasourceDSRef 
        add constraint FKFDA42FCCB906E03 
        foreign key (slds_id) 
        references JIDomainDatasource;

    alter table JIDomainDatasourceDSRef 
        add constraint FKFDA42FC7106B699 
        foreign key (ref_id) 
        references JIResource;

    alter table JIFTPInfoProperties 
        add constraint FK6BD68B04D5FA3F0A 
        foreign key (repodest_id) 
        references JIReportJobRepoDest;

    alter table JIFileResource 
        add constraint FKF75B5889A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIFileResource 
        add constraint FKF75B58895A0C539 
        foreign key (reference) 
        references JIFileResource;

    alter table JIInputControl 
        add constraint FKCAC6A512120E06F7 
        foreign key (data_type) 
        references JIDataType;

    alter table JIInputControl 
        add constraint FKCAC6A512A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIInputControl 
        add constraint FKCAC6A51262A86F04 
        foreign key (list_of_values) 
        references JIListOfValues;

    alter table JIInputControl 
        add constraint FKCAC6A512B37DB6EB 
        foreign key (list_query) 
        references JIQuery;

    alter table JIInputControlQueryColumn 
        add constraint FKE436A5CCE7922149 
        foreign key (input_control_id) 
        references JIInputControl;

    alter table JIJNDIJdbcDatasource 
        add constraint FK7F9DA248A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIJdbcDatasource 
        add constraint FKC8BDFCBFA8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIAwsDatasource
        add constraint FK6085542387E4472B
        foreign key (id)
        references JIJdbcDatasource;

    alter table JIListOfValues 
        add constraint FK4E86A776A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIListOfValuesItem 
        add constraint FKD37CEBA993F0E1F6 
        foreign key (id) 
        references JIListOfValues;

    alter table JILogEvent 
        add constraint FK5F32081591865AF 
        foreign key (userId) 
        references JIUser;

    alter table JIMondrianConnection 
        add constraint FK4FF53B191D51BFAD 
        foreign key (id) 
        references JIOlapClientConnection;

    alter table JIMondrianConnection 
        add constraint FK4FF53B19324CFECB 
        foreign key (reportDataSource) 
        references JIResource;

    alter table JIMondrianConnection 
        add constraint FK4FF53B19C495A60B 
        foreign key (mondrianSchema) 
        references JIFileResource;

    alter table JIMondrianConnectionGrant 
        add constraint FK3DDE9D8346D80AD2 
        foreign key (mondrianConnectionId) 
        references JIMondrianConnection;

    alter table JIMondrianConnectionGrant 
        add constraint FK3DDE9D83FFAC5026 
        foreign key (accessGrant) 
        references JIFileResource;

    alter table JIMondrianXMLADefinition 
        add constraint FK313B2AB8A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIMondrianXMLADefinition 
        add constraint FK313B2AB8801D6C37 
        foreign key (mondrianConnection) 
        references JIMondrianConnection;

    create index uri_index on JIObjectPermission (uri);

    alter table JIOlapClientConnection 
        add constraint FK3CA3B7D4A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIOlapUnit 
        add constraint FKF034DCCFA8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIOlapUnit 
        add constraint FKF034DCCF8F542247 
        foreign key (olapClientConnection) 
        references JIOlapClientConnection;

    alter table JIQuery 
        add constraint FKCBCB0EC9A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIQuery 
        add constraint FKCBCB0EC92B329A97 
        foreign key (dataSource) 
        references JIResource;

    alter table JIReportAlertToAddress 
        add constraint FKC4E3713022FA4CBA 
        foreign key (alert_id) 
        references JIReportJobAlert;

    alter table JIReportJob 
        add constraint FK156F5F6AE4D73E35 
        foreign key (mail_notification) 
        references JIReportJobMail;

    alter table JIReportJob 
        add constraint FK156F5F6AC83ABB38 
        foreign key (alert) 
        references JIReportJobAlert;

    alter table JIReportJob 
        add constraint FK156F5F6A9EEC902C 
        foreign key (content_destination) 
        references JIReportJobRepoDest;

    alter table JIReportJob 
        add constraint FK156F5F6A74D2696E 
        foreign key (job_trigger) 
        references JIReportJobTrigger;

    alter table JIReportJob 
        add constraint FK156F5F6A4141263C 
        foreign key (owner) 
        references JIUser;

    alter table JIReportJobCalendarTrigger 
        add constraint FKC374C7D0D2B2EB53 
        foreign key (id) 
        references JIReportJobTrigger;

    alter table JIReportJobMailRecipient 
        add constraint FKBB6DB6D880001AAE 
        foreign key (destination_id) 
        references JIReportJobMail;

    alter table JIReportJobOutputFormat 
        add constraint FKB42A5CE2C3389A8 
        foreign key (report_job_id) 
        references JIReportJob;

    alter table JIReportJobParameter 
        add constraint FKEAC52B5F2EC643D 
        foreign key (job_id) 
        references JIReportJob;

    alter table JIReportJobSimpleTrigger 
        add constraint FKB9337C5CD2B2EB53 
        foreign key (id) 
        references JIReportJobTrigger;

    create index time_stamp_index on JIReportMonitoringFact (time_stamp);

    create index user_name_index on JIReportMonitoringFact (user_name);

    create index query_execution_time_index on JIReportMonitoringFact (query_execution_time);

    create index time_minute_index on JIReportMonitoringFact (time_minute);

    create index user_organization_index on JIReportMonitoringFact (user_organization);

    create index date_day_index on JIReportMonitoringFact (date_day);

    create index date_year_index on JIReportMonitoringFact (date_year);

    create index total_report_exec_time_index on JIReportMonitoringFact (total_report_execution_time);

    create index time_hour_index on JIReportMonitoringFact (time_hour);

    create index date_month_index on JIReportMonitoringFact (date_month);

    create index report_uri_index on JIReportMonitoringFact (report_uri);

    create index editing_action_index on JIReportMonitoringFact (editing_action);

    create index event_context_index on JIReportMonitoringFact (event_context);

    create index report_rendering_time_index on JIReportMonitoringFact (report_rendering_time);

    create index event_type_index_2 on JIReportMonitoringFact (event_type);

    alter table JIReportOptions 
        add constraint resource_id 
        foreign key (id) 
        references JIResource;

    alter table JIReportOptions 
        add constraint report_fk 
        foreign key (report_id) 
        references JIReportUnit;

    alter table JIReportOptionsInput 
        add constraint options_fk 
        foreign key (options_id) 
        references JIReportOptions;

    alter table JIReportUnit 
        add constraint FK98818B77A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIReportUnit 
        add constraint FK98818B778FDA11CC 
        foreign key (query) 
        references JIQuery;

    alter table JIReportUnit 
        add constraint FK98818B77324CFECB 
        foreign key (reportDataSource) 
        references JIResource;

    alter table JIReportUnit 
        add constraint FK98818B778C8DF21B 
        foreign key (mainReport) 
        references JIFileResource;

    alter table JIReportUnitInputControl 
        add constraint FK5FBE934AE7922149 
        foreign key (input_control_id) 
        references JIInputControl;

    alter table JIReportUnitInputControl 
        add constraint FK5FBE934AA6A48880 
        foreign key (report_unit_id) 
        references JIReportUnit;

    alter table JIReportUnitResource 
        add constraint FK8B1C4CA5A6A48880 
        foreign key (report_unit_id) 
        references JIReportUnit;

    alter table JIReportUnitResource 
        add constraint FK8B1C4CA5865B10DA 
        foreign key (resource_id) 
        references JIFileResource;

    alter table JIRepositoryCache 
        add constraint FKE7338B19E7C5A6 
        foreign key (item_reference) 
        references JIRepositoryCache;

    create index resource_type_index on JIResource (resourceType);

    alter table JIResource 
        add constraint FKD444826DA58002DF 
        foreign key (childrenFolder) 
        references JIResourceFolder;

    alter table JIResource 
        add constraint FKD444826DA08E2155 
        foreign key (parent_folder) 
        references JIResourceFolder;

    alter table JIResourceFolder 
        add constraint FK7F24453BA08E2155 
        foreign key (parent_folder) 
        references JIResourceFolder;

    alter table JIRole 
        add constraint FK82724655E415AC2D 
        foreign key (tenantId) 
        references JITenant;

    alter table JITenant 
        add constraint FKB1D7B2C97803CC2D 
        foreign key (parentId) 
        references JITenant;

    alter table JIUser 
        add constraint FK8273B1AAE415AC2D 
        foreign key (tenantId) 
        references JITenant;

    alter table JIUserRole 
        add constraint FKD8B5C1403C31045 
        foreign key (roleId) 
        references JIRole;

    alter table JIUserRole 
        add constraint FKD8B5C14091865AF 
        foreign key (userId) 
        references JIUser;

    alter table JIVirtualDataSourceUriMap 
        add constraint FK4A6CCE019E600E20 
        foreign key (virtualDS_id) 
        references JIVirtualDatasource;

    alter table JIVirtualDataSourceUriMap 
        add constraint FK4A6CCE01F254B53E 
        foreign key (resource_id) 
        references JIResource;

    alter table JIVirtualDatasource 
        add constraint FK30E55631A8BF376D 
        foreign key (id) 
        references JIResource;

    alter table JIXMLAConnection 
        add constraint FK94C688A71D51BFAD 
        foreign key (id) 
        references JIOlapClientConnection;

    alter table ProfilingRecord 
        add constraint FK92D5BBF7DACDD6DA 
        foreign key (parent_id) 
        references ProfilingRecord;
