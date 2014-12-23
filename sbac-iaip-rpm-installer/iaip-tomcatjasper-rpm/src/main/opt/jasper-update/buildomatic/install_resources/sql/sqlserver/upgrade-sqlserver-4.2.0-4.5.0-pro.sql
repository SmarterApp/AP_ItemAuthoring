
    ALTER TABLE JIQuery
        ALTER COLUMN sql_query NVARCHAR(MAX) NOT NULL;

--

    ALTER TABLE JIContentResource
        ALTER COLUMN data VARBINARY(MAX) NULL;

    ALTER TABLE JIFileResource
        ALTER COLUMN data VARBINARY(MAX) NULL;

    ALTER TABLE JILogEvent
        ALTER COLUMN event_data VARBINARY(MAX) NULL;

    ALTER TABLE JIOlapUnit
        ALTER COLUMN view_options VARBINARY(MAX) NULL;

    ALTER TABLE JIReportJobParameter
        ALTER COLUMN parameter_value VARBINARY(MAX) NULL;

    ALTER TABLE JIRepositoryCache
        ALTER COLUMN data VARBINARY(MAX) NULL;

--

    ALTER TABLE JIOlapUnit
        ALTER COLUMN mdx_query NVARCHAR(MAX) NOT NULL;

--

    EXEC sp_rename 'JIDataType.maxValue', 'max_value', 'COLUMN';