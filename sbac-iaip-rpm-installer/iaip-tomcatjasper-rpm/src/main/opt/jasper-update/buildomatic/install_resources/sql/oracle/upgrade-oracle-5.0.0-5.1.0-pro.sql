--
-- Create new table and indices for monitoring
--

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

    alter table JIAwsDatasource
        add constraint FK6085542387E4472B
        foreign key (id)
        references JIJdbcDatasource;
