--
-- Create new table and indices for monitoring
--

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

    alter table JIAwsDatasource
        add constraint FK6085542387E4472B
        foreign key (id)
        references JIJdbcDatasource;
