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

create table JIDataDefinerUnit (
    id numeric(19,0) not null,
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

alter table JIInputControl
    alter column query_value_column nvarchar(200) null;

alter table JIInputControlQueryColumn
    alter column query_column nvarchar(200) not null;

alter table JIJdbcDatasource
    alter column connectionUrl nvarchar(500) null;

alter table JILogEvent
    alter column event_text ntext null;


alter table JIReportJobMail
    alter column message nvarchar(2000) null;

alter table JIReportJobRepoDest
    add output_description nvarchar(250) null,
    timestamp_pattern nvarchar(250) null;
    
alter table JIReportOptions
    alter column options_name nvarchar(210) not null;

alter table JIUser
    add previousPasswordChangeTime datetime null;


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

delete from JIRepositoryCache;
