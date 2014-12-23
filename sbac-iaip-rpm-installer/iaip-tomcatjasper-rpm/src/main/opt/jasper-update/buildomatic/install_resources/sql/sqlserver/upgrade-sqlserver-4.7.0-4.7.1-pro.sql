
--Only run this script if you upgraded to JasperReports Server 4.7.0 from a 4.5.0 or 4.5.1 JRS using the js-upgrade-samedb script, 
--fix to bug #28757

ALTER TABLE JIDataSnapshotContents ALTER COLUMN data varbinary(max) not null;

ALTER TABLE JIReportAlertToAddress DROP CONSTRAINT FKC4E3713022FA4CBA;
ALTER TABLE JIReportJob DROP CONSTRAINT FK156F5F6AC83ABB38;

DROP TABLE JIReportJobAlert;

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

    alter table JIReportAlertToAddress
        add constraint FKC4E3713022FA4CBA
        foreign key (alert_id)
        references JIReportJobAlert;

    alter table JIReportJob
        add constraint FK156F5F6AC83ABB38
        foreign key (alert)
        references JIReportJobAlert;

ALTER TABLE JIDataSnapshotParameter DROP CONSTRAINT id_fk_idx;
ALTER TABLE JIDataSnapshotParameter DROP CONSTRAINT ji_data_snapshot_parameter_pkey;
ALTER TABLE JIDataSnapshotContents DROP CONSTRAINT ji_data_snapshot_contents_pkey;
ALTER TABLE JIDataSnapshot DROP CONSTRAINT ji_data_snapshot_pkey;

DROP TABLE JIDataSnapshotContents;
DROP TABLE JIDataSnapshot;

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

ALTER TABLE JIDataSnapshotParameter ADD CONSTRAINT ji_data_snapshot_parameter_pkey PRIMARY KEY (id, parameter_name);
ALTER TABLE JIDataSnapshotParameter ADD CONSTRAINT id_fk_idx foreign key (id) references JIDataSnapshot;