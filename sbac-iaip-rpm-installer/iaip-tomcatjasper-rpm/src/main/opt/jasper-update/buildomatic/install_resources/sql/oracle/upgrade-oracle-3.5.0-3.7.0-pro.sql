    create table JIAccessEvent (
        id number(19,0) not null,
        user_id number(19,0) not null,
        event_date date not null,
        resource_id number(19,0) not null,
        updating number(1,0) not null,
        primary key (id)
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

    alter table JIResource
        add update_date date;
    update JIResource 
        set update_date = creation_date;
    alter table JIResource 
        modify update_date date NOT NULL;

    alter table JIResourceFolder
        add update_date date;
    update JIResourceFolder 
        set update_date = creation_date;
    alter table JIResourceFolder
        modify update_date date NOT NULL;

    alter table JITenant
        add tenantAlias nvarchar2(100);
    update JITenant
        set tenantAlias = tenantId;
    alter table JITenant
        modify tenantAlias nvarchar2(100) NOT NULL;


    create index access_upd_index on JIAccessEvent (updating);

    create index access_res_index on JIAccessEvent (resource_id);

    create index access_user_index on JIAccessEvent (user_id);

    create index access_date_index on JIAccessEvent (event_date);


    alter table JIAccessEvent 
        add constraint FK47FB3CD732282198 
        foreign key (user_id) 
        references JIUser;

    alter table JIAccessEvent 
        add constraint FK47FB3CD7F254B53E 
        foreign key (resource_id) 
        references JIResource;


    create index resource_uri_index on JIAuditEvent (resource_uri);

    create index request_type_index on JIAuditEvent (request_type);

    create index res_type_index on JIAuditEvent (resource_type);

    create index event_date_index on JIAuditEvent (event_date);

    create index tenant_id_index on JIAuditEvent (tenant_id);

    create index event_type_index on JIAuditEvent (event_type);

    create index username_index on JIAuditEvent (username);


    alter table JIAuditEventProperty 
        add constraint FK3429FE136F667020 
        foreign key (audit_event_id) 
        references JIAuditEvent;

    alter table JIAuditEventPropertyArchive 
        add constraint FKD2940F2F637AC28A 
        foreign key (audit_event_id) 
        references JIAuditEventArchive;



 
