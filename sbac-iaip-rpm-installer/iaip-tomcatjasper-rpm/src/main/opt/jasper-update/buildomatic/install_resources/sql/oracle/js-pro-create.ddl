
    create table JIAccessEvent (
        id number(19,0) not null,
        user_id number(19,0) not null,
        event_date date not null,
        resource_id number(19,0) not null,
        updating number(1,0) not null,
        primary key (id)
    );

    create table JIAdhocChartMeasure (
        id number(19,0) not null,
        name nvarchar2(255) not null,
        label nvarchar2(255),
        width number(10,0),
        jiFunction nvarchar2(255),
        type nvarchar2(255),
        mask nvarchar2(255),
        functionMask nvarchar2(255),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JIAdhocColumn (
        id number(19,0) not null,
        name nvarchar2(255) not null,
        label nvarchar2(255),
        width number(10,0),
        jiFunction nvarchar2(255),
        type nvarchar2(255),
        mask nvarchar2(255),
        functionMask nvarchar2(255),
        idx number(10,0) not null,
        primary key (id, idx)
    );

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

    create table JIAdhocGroup (
        id number(19,0) not null,
        name nvarchar2(255) not null,
        label nvarchar2(255),
        type nvarchar2(255),
        mask nvarchar2(255),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JIAdhocReportUnit (
        id number(19,0) not null,
        adhocStateId number(19,0),
        primary key (id)
    );

    create table JIAdhocState (
        id number(19,0) not null,
        type nvarchar2(255) not null,
        theme nvarchar2(255),
        title nvarchar2(255),
        pageOrientation nvarchar2(255),
        paperSize nvarchar2(255),
        maxRows number(10,0),
        summaryLabel nvarchar2(255),
        group_name nvarchar2(255),
        group_label nvarchar2(255),
        group_type nvarchar2(255),
        group_mask nvarchar2(255),
        primary key (id)
    );

    create table JIAdhocStateProperty (
        state_id number(19,0) not null,
        value nvarchar2(1000),
        name nvarchar2(100) not null,
        primary key (state_id, name)
    );

    create table JIAdhocTableSortField (
        id number(19,0) not null,
        fieldName nvarchar2(255) not null,
        ascending number(1,0),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JIAdhocXTabColumnGroup (
        id number(19,0) not null,
        name nvarchar2(255) not null,
        label nvarchar2(255),
        type nvarchar2(255),
        categorizer nvarchar2(1000),
        fieldName nvarchar2(255),
        fieldType nvarchar2(255),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JIAdhocXTabMeasure (
        id number(19,0) not null,
        name nvarchar2(255) not null,
        label nvarchar2(255),
        width number(10,0),
        jiFunction nvarchar2(255),
        type nvarchar2(255),
        mask nvarchar2(255),
        functionMask nvarchar2(255),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JIAdhocXTabRowGroup (
        id number(19,0) not null,
        name nvarchar2(255) not null,
        label nvarchar2(255),
        type nvarchar2(255),
        categorizer nvarchar2(1000),
        fieldName nvarchar2(255),
        fieldType nvarchar2(255),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JIAuditEvent (
        id number(19,0) not null,
        username nvarchar2(100),
        tenant_id nvarchar2(100),
        event_date date not null,
        resource_uri nvarchar2(250),
        resource_type nvarchar2(250),
        event_type nvarchar2(100) not null,
        request_type nvarchar2(100) not null,
        primary key (id)
    );

    create table JIAuditEventArchive (
        id number(19,0) not null,
        username nvarchar2(100),
        tenant_id nvarchar2(100),
        event_date date not null,
        resource_uri nvarchar2(250),
        resource_type nvarchar2(250),
        event_type nvarchar2(100) not null,
        request_type nvarchar2(100) not null,
        primary key (id)
    );

    create table JIAuditEventProperty (
        id number(19,0) not null,
        property_type nvarchar2(100) not null,
        value nvarchar2(250),
        clob_value nclob,
        audit_event_id number(19,0) not null,
        primary key (id)
    );

    create table JIAuditEventPropertyArchive (
        id number(19,0) not null,
        property_type nvarchar2(100) not null,
        value nvarchar2(250),
        clob_value nclob,
        audit_event_id number(19,0) not null,
        primary key (id)
    );

    create table JIBeanDatasource (
        id number(19,0) not null,
        beanName nvarchar2(100) not null,
        beanMethod nvarchar2(100),
        primary key (id)
    );

    create table JIContentResource (
        id number(19,0) not null,
        data blob,
        file_type nvarchar2(20),
        primary key (id)
    );

    create table JICustomDatasource (
        id number(19,0) not null,
        serviceClass nvarchar2(250) not null,
        primary key (id)
    );

    create table JICustomDatasourceProperty (
        ds_id number(19,0) not null,
        value nvarchar2(1000),
        name nvarchar2(100) not null,
        primary key (ds_id, name)
    );

    create table JIDashboard (
        id number(19,0) not null,
        adhocStateId number(19,0),
        primary key (id)
    );

    create table JIDashboardFrameProperty (
        id number(19,0) not null,
        frameName nvarchar2(255) not null,
        frameClassName nvarchar2(255) not null,
        propertyName nvarchar2(255) not null,
        propertyValue nvarchar2(1000),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JIDashboardResource (
        dashboard_id number(19,0) not null,
        resource_id number(19,0) not null,
        resource_index number(10,0) not null,
        primary key (dashboard_id, resource_index)
    );

    create table JIDataDefinerUnit (
        id number(19,0) not null,
        primary key (id)
    );

    create table JIDataSnapshot (
        id number(19,0) not null,
        version number(10,0) not null,
        snapshot_date date,
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

    create table JIDataType (
        id number(19,0) not null,
        type number(3,0),
        maxLength number(10,0),
        decimals number(10,0),
        regularExpr nvarchar2(255),
        minValue raw(255),
        max_value raw(255),
        strictMin number(1,0),
        strictMax number(1,0),
        primary key (id)
    );

    create table JIDomainDatasource (
        id number(19,0) not null,
        schema_id number(19,0) not null,
        security_id number(19,0),
        primary key (id)
    );

    create table JIDomainDatasourceBundle (
        slds_id number(19,0) not null,
        locale nvarchar2(20),
        bundle_id number(19,0) not null,
        idx number(10,0) not null,
        primary key (slds_id, idx)
    );

    create table JIDomainDatasourceDSRef (
        slds_id number(19,0) not null,
        ref_id number(19,0) not null,
        alias nvarchar2(100) not null,
        primary key (slds_id, alias)
    );

    create table JIFTPInfoProperties (
        repodest_id number(19,0) not null,
        property_value nvarchar2(250),
        property_name nvarchar2(100) not null,
        primary key (repodest_id, property_name)
    );

    create table JIFileResource (
        id number(19,0) not null,
        data blob,
        file_type nvarchar2(20),
        reference number(19,0),
        primary key (id)
    );

    create table JIInputControl (
        id number(19,0) not null,
        type number(3,0),
        mandatory number(1,0),
        readOnly number(1,0),
        visible number(1,0),
        data_type number(19,0),
        list_of_values number(19,0),
        list_query number(19,0),
        query_value_column nvarchar2(200),
        defaultValue raw(255),
        primary key (id)
    );

    create table JIInputControlQueryColumn (
        input_control_id number(19,0) not null,
        query_column nvarchar2(200) not null,
        column_index number(10,0) not null,
        primary key (input_control_id, column_index)
    );

    create table JIJNDIJdbcDatasource (
        id number(19,0) not null,
        jndiName nvarchar2(100) not null,
        timezone nvarchar2(100),
        primary key (id)
    );

    create table JIJdbcDatasource (
        id number(19,0) not null,
        driver nvarchar2(100) not null,
        password nvarchar2(100),
        connectionUrl nvarchar2(500),
        username nvarchar2(100),
        timezone nvarchar2(100),
        primary key (id)
    );

    create table JIAwsDatasource (
        id number(19,0) not null,
        accessKey nvarchar2(100),
        secretKey nvarchar2(100),
        roleARN nvarchar2(100),
        region nvarchar2(100) not null,
        dbName nvarchar2(100) not null,
        dbInstanceIdentifier nvarchar2(100) not null,
        dbService nvarchar2(100) not null,
        primary key (id)
    );

    create table JIListOfValues (
        id number(19,0) not null,
        primary key (id)
    );

    create table JIListOfValuesItem (
        id number(19,0) not null,
        label nvarchar2(255),
        value raw(255),
        idx number(10,0) not null,
        primary key (id, idx)
    );

    create table JILogEvent (
        id number(19,0) not null,
        occurrence_date date not null,
        event_type number(3,0) not null,
        component nvarchar2(100),
        message nvarchar2(250) not null,
        resource_uri nvarchar2(250),
        event_text nclob,
        event_data blob,
        event_state number(3,0),
        userId number(19,0),
        primary key (id)
    );

    create table JIMondrianConnection (
        id number(19,0) not null,
        reportDataSource number(19,0),
        mondrianSchema number(19,0),
        primary key (id)
    );

    create table JIMondrianConnectionGrant (
        mondrianConnectionId number(19,0) not null,
        accessGrant number(19,0) not null,
        grantIndex number(10,0) not null,
        primary key (mondrianConnectionId, grantIndex)
    );

    create table JIMondrianXMLADefinition (
        id number(19,0) not null,
        catalog nvarchar2(100) not null,
        mondrianConnection number(19,0),
        primary key (id)
    );

    create table JIObjectPermission (
        id number(19,0) not null,
        uri nvarchar2(250) not null,
        recipientobjectclass nvarchar2(250),
        recipientobjectid number(19,0),
        permissionMask number(10,0) not null,
        primary key (id)
    );

    create table JIOlapClientConnection (
        id number(19,0) not null,
        primary key (id)
    );

    create table JIOlapUnit (
        id number(19,0) not null,
        olapClientConnection number(19,0),
        mdx_query nclob not null,
        view_options blob,
        primary key (id)
    );

    create table JIProfileAttribute (
        id number(19,0) not null,
        attrName nvarchar2(255) not null,
        attrValue nvarchar2(255) not null,
        principalobjectclass nvarchar2(255) not null,
        principalobjectid number(19,0) not null,
        primary key (id)
    );

    create table JIQuery (
        id number(19,0) not null,
        dataSource number(19,0),
        query_language nvarchar2(40) not null,
        sql_query nclob not null,
        primary key (id)
    );

    create table JIReportAlertToAddress (
        alert_id number(19,0) not null,
        to_address nvarchar2(100) not null,
        to_address_idx number(10,0) not null,
        primary key (alert_id, to_address_idx)
    );

    create table JIReportJob (
        id number(19,0) not null,
        version number(10,0) not null,
        owner number(19,0) not null,
        label nvarchar2(100) not null,
        description nvarchar2(2000),
        creation_date date,
        report_unit_uri nvarchar2(250) not null,
        job_trigger number(19,0) not null,
        base_output_name nvarchar2(100) not null,
        output_locale nvarchar2(20),
        content_destination number(19,0),
        mail_notification number(19,0),
        alert number(19,0),
        primary key (id)
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

    create table JIReportJobCalendarTrigger (
        id number(19,0) not null,
        minutes nvarchar2(200) not null,
        hours nvarchar2(80) not null,
        days_type number(3,0) not null,
        week_days nvarchar2(20),
        month_days nvarchar2(100),
        months nvarchar2(40) not null,
        primary key (id)
    );

    create table JIReportJobMail (
        id number(19,0) not null,
        version number(10,0) not null,
        subject nvarchar2(100) not null,
        message nvarchar2(2000),
        send_type number(3,0) not null,
        skip_empty number(1,0) not null,
        message_text_when_job_fails nvarchar2(2000),
        inc_stktrc_when_job_fails number(1,0) not null,
        skip_notif_when_job_fails number(1,0) not null,
        primary key (id)
    );

    create table JIReportJobMailRecipient (
        destination_id number(19,0) not null,
        recipient_type number(3,0) not null,
        address nvarchar2(100) not null,
        recipient_idx number(10,0) not null,
        primary key (destination_id, recipient_idx)
    );

    create table JIReportJobOutputFormat (
        report_job_id number(19,0) not null,
        output_format number(3,0) not null,
        primary key (report_job_id, output_format)
    );

    create table JIReportJobParameter (
        job_id number(19,0) not null,
        parameter_value blob,
        parameter_name nvarchar2(100) not null,
        primary key (job_id, parameter_name)
    );

    create table JIReportJobRepoDest (
        id number(19,0) not null,
        version number(10,0) not null,
        folder_uri nvarchar2(250),
        sequential_filenames number(1,0) not null,
        overwrite_files number(1,0) not null,
        save_to_repository number(1,0) not null,
        output_description nvarchar2(250),
        timestamp_pattern nvarchar2(250),
        using_def_rpt_opt_folder_uri number(1,0) not null,
        output_local_folder nvarchar2(250),
        user_name nvarchar2(50),
        password nvarchar2(50),
        server_name nvarchar2(150),
        folder_path nvarchar2(250),
        primary key (id)
    );

    create table JIReportJobSimpleTrigger (
        id number(19,0) not null,
        occurrence_count number(10,0) not null,
        recurrence_interval number(10,0),
        recurrence_interval_unit number(3,0),
        primary key (id)
    );

    create table JIReportJobTrigger (
        id number(19,0) not null,
        version number(10,0) not null,
        timezone nvarchar2(40),
        start_type number(3,0) not null,
        start_date date,
        end_date date,
        calendar_name nvarchar2(50),
        misfire_instruction number(10,0) not null,
        primary key (id)
    );

    create table JIReportMonitoringFact (
        id number(19,0) not null,
        date_year number(5,0) not null,
        date_month number(3,0) not null,
        date_day number(3,0) not null,
        time_hour number(3,0) not null,
        time_minute number(3,0) not null,
        event_context nvarchar2(255) not null,
        user_organization nvarchar2(255),
        user_name nvarchar2(255),
        event_type nvarchar2(255) not null,
        report_uri nvarchar2(255),
        editing_action nvarchar2(255),
        query_execution_time number(10,0) not null,
        report_rendering_time number(10,0) not null,
        total_report_execution_time number(10,0) not null,
        time_stamp date not null,
        primary key (id)
    );

    create table JIReportOptions (
        id number(19,0) not null,
        options_name nvarchar2(210) not null,
        report_id number(19,0) not null,
        primary key (id)
    );

    create table JIReportOptionsInput (
        options_id number(19,0) not null,
        input_value raw(1000),
        input_name nvarchar2(100) not null,
        primary key (options_id, input_name)
    );

    create table JIReportUnit (
        id number(19,0) not null,
        reportDataSource number(19,0),
        query number(19,0),
        mainReport number(19,0),
        controlrenderer nvarchar2(100),
        reportrenderer nvarchar2(100),
        promptcontrols number(1,0),
        controlslayout number(3,0),
        data_snapshot_id number(19,0),
        primary key (id)
    );

    create table JIReportUnitInputControl (
        report_unit_id number(19,0) not null,
        input_control_id number(19,0) not null,
        control_index number(10,0) not null,
        primary key (report_unit_id, control_index)
    );

    create table JIReportUnitResource (
        report_unit_id number(19,0) not null,
        resource_id number(19,0) not null,
        resource_index number(10,0) not null,
        primary key (report_unit_id, resource_index)
    );

    create table JIRepositoryCache (
        id number(19,0) not null,
        uri nvarchar2(250) not null,
        cache_name nvarchar2(20) not null,
        data blob,
        version number(10,0) not null,
        version_date date not null,
        item_reference number(19,0),
        primary key (id),
        unique (uri, cache_name)
    );

    create table JIResource (
        id number(19,0) not null,
        version number(10,0) not null,
        name nvarchar2(100) not null,
        parent_folder number(19,0) not null,
        childrenFolder number(19,0),
        label nvarchar2(100) not null,
        description nvarchar2(250),
        resourceType nvarchar2(255) not null,
        creation_date date not null,
        update_date date not null,
        primary key (id),
        unique (name, parent_folder)
    );

    create table JIResourceFolder (
        id number(19,0) not null,
        version number(10,0) not null,
        uri nvarchar2(250) not null,
        hidden number(1,0),
        name nvarchar2(100) not null,
        label nvarchar2(100) not null,
        description nvarchar2(250),
        parent_folder number(19,0),
        creation_date date not null,
        update_date date not null,
        primary key (id),
        unique (uri)
    );

    create table JIRole (
        id number(19,0) not null,
        rolename nvarchar2(100) not null,
        tenantId number(19,0) not null,
        externallyDefined number(1,0),
        primary key (id),
        unique (rolename, tenantId)
    );

    create table JITenant (
        id number(19,0) not null,
        tenantId nvarchar2(100) not null,
        tenantAlias nvarchar2(100) not null,
        parentId number(19,0),
        tenantName nvarchar2(100) not null,
        tenantDesc nvarchar2(250),
        tenantNote nvarchar2(250),
        tenantUri nvarchar2(250) not null,
        tenantFolderUri nvarchar2(250) not null,
        theme nvarchar2(250),
        primary key (id),
        unique (tenantId)
    );

    create table JIUser (
        id number(19,0) not null,
        username nvarchar2(100) not null,
        tenantId number(19,0) not null,
        fullname nvarchar2(100) not null,
        emailAddress nvarchar2(100),
        password nvarchar2(100),
        externallyDefined number(1,0),
        enabled number(1,0),
        previousPasswordChangeTime date,
        primary key (id),
        unique (username, tenantId)
    );

    create table JIUserRole (
        roleId number(19,0) not null,
        userId number(19,0) not null,
        primary key (userId, roleId)
    );

    create table JIVirtualDataSourceUriMap (
        virtualDS_id number(19,0) not null,
        resource_id number(19,0) not null,
        data_source_name nvarchar2(100) not null,
        primary key (virtualDS_id, data_source_name)
    );

    create table JIVirtualDatasource (
        id number(19,0) not null,
        timezone nvarchar2(100),
        primary key (id)
    );

    create table JIXMLAConnection (
        id number(19,0) not null,
        catalog nvarchar2(100) not null,
        username nvarchar2(100) not null,
        password nvarchar2(100) not null,
        datasource nvarchar2(100) not null,
        uri nvarchar2(100) not null,
        primary key (id)
    );

    create table ProfilingRecord (
        id number(19,0) not null,
        parent_id number(19,0),
        duration_ms number(19,0),
        description nvarchar2(1000),
        begin_date date not null,
        cache_hit number(1,0),
        agg_hit number(1,0),
        sql_query number(1,0),
        mdx_query number(1,0),
        begin_year number(10,0) not null,
        begin_month number(10,0) not null,
        begin_day number(10,0) not null,
        begin_hour number(10,0) not null,
        begin_min number(10,0) not null,
        begin_sec number(10,0) not null,
        begin_ms number(10,0) not null,
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

    create sequence hibernate_sequence;
