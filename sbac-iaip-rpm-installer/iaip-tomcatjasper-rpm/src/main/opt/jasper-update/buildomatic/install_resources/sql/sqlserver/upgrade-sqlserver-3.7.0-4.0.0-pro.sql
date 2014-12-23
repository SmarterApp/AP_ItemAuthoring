
    alter table JITenant add
        theme nvarchar(250);
    update JITenant set
        theme = 'default';
    delete from JIRepositoryCache;
