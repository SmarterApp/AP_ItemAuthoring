--
-- Create new table and indices for monitoring
--

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

--
-- Create new tables for virtual data source
--
	
	create table JIVirtualDataSourceUriMap (
        virtualDS_id numeric(19,0) not null,
        resource_id numeric(19,0) not null,
        data_source_name nvarchar(100) not null,
        primary key (virtualDS_id, data_source_name)
    );
	
	
	create table JIVirtualDatasource (
        id numeric(19,0) not null,
        timezone nvarchar(100),
        primary key (id)
    );
		
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
		