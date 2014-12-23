
    alter table JITenant add
        theme nvarchar2(250);
    update JITenant set
        theme = 'default';
    delete from JIRepositoryCache;
