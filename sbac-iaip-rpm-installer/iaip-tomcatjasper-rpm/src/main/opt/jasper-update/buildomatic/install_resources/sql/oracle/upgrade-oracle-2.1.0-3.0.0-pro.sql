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

	create table JIDataDefinerUnit (
        id number(19,0) not null,
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

	alter table JIInputControl
				modify query_value_column nvarchar2(200);

	alter table JIInputControlQueryColumn
				modify query_column nvarchar2(200);

	alter table JIJdbcDatasource
				modify connectionUrl nvarchar2(500);

	alter table JILogEvent rename column event_text to event_text_2;
	alter table JILogEvent
				add event_text nclob;
	update JILogEvent set event_text=event_text_2;
	alter table JILogEvent drop (event_text_2);

	alter table JILogEvent
				modify event_data blob;

	alter table JIProfileAttribute
				modify principalobjectclass nvarchar2(255) not null;

	alter table JIProfileAttribute
				modify principalobjectid number(19,0) not null;

	alter table JIReportJobMail
				modify message nvarchar2(2000);

	alter table JIReportJobRepoDest
				add output_description nvarchar2(250);

	alter table JIReportJobRepoDest
				add timestamp_pattern nvarchar2(250);

	alter table JIReportOptions
				modify options_name nvarchar2(210);

	alter table JIUser
				add previousPasswordChangeTime date;

	alter table JIDashboard 
        add constraint FKEC09F81531211827 
        foreign key (adhocStateId) 
        references JIAdhocState;

	alter table JIDashboard 
        add constraint FKEC09F815A8BF376D 
        foreign key (id) 
        references JIResource;

	alter table JIDashboardFrameProperty 
        add constraint FK679EF04DFA08F0B4 
        foreign key (id) 
        references JIAdhocState;

	alter table JIDataDefinerUnit 
        add constraint FK1EC11AF2981B13F0 
        foreign key (id) 
        references JIReportUnit;

	alter table JIDomainDatasource 
        add constraint FK59F8EB8833A6D267 
        foreign key (schema_id) 
        references JIFileResource;

	alter table JIDomainDatasource 
        add constraint FK59F8EB88992A3868 
        foreign key (security_id) 
        references JIFileResource;

	alter table JIDomainDatasource 
        add constraint FK59F8EB88A8BF376D 
        foreign key (id) 
        references JIResource;

	alter table JIDomainDatasourceBundle 
        add constraint FKE9F0422AE494DFE6 
        foreign key (bundle_id) 
        references JIFileResource;

	alter table JIDomainDatasourceBundle 
        add constraint FKE9F0422ACB906E03 
        foreign key (slds_id) 
        references JIDomainDatasource;

	alter table JIDomainDatasourceDSRef 
        add constraint FKFDA42FC7106B699 
        foreign key (ref_id) 
        references JIResource;

	alter table JIDomainDatasourceDSRef 
        add constraint FKFDA42FCCB906E03 
        foreign key (slds_id) 
        references JIDomainDatasource;

	
