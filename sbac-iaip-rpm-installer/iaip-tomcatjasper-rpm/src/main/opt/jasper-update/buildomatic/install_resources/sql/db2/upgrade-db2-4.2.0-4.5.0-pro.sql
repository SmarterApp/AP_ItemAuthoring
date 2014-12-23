
    ALTER TABLE JIQuery
        ADD COLUMN new_sql_query CLOB(400000);
    UPDATE JIQuery
        SET new_sql_query = CAST (sql_query AS CLOB(400000));
    COMMIT;

    ALTER TABLE JIQuery
        ALTER COLUMN new_sql_query SET NOT NULL;

    ALTER TABLE JIQuery
        DROP COLUMN sql_query;
    ALTER TABLE JIQuery
        RENAME COLUMN new_sql_query TO sql_query;

    CALL SYSPROC.ADMIN_CMD('REORG TABLE JIQuery');
--

    ALTER TABLE JIReportJobParameter
        ADD COLUMN new_parameter_value BLOB(20971520);
    UPDATE JIReportJobParameter
        SET new_parameter_value = CAST (parameter_value AS BLOB(20971520));
    COMMIT;

    ALTER TABLE JIReportJobParameter
        DROP COLUMN parameter_value;
    ALTER TABLE JIReportJobParameter
        RENAME COLUMN new_parameter_value TO parameter_value;

    CALL SYSPROC.ADMIN_CMD('REORG TABLE JIReportJobParameter');
--

    ALTER TABLE JIOlapUnit
        ADD COLUMN new_mdx_query CLOB(400000);
    UPDATE JIOlapUnit
        SET new_mdx_query = CAST (mdx_query AS CLOB(400000));
    COMMIT;

    ALTER TABLE JIOlapUnit
        ALTER COLUMN new_mdx_query SET NOT NULL;

    ALTER TABLE JIOlapUnit
        DROP COLUMN mdx_query;
    ALTER TABLE JIOlapUnit
        RENAME COLUMN new_mdx_query TO mdx_query;

    CALL SYSPROC.ADMIN_CMD('REORG TABLE JIOlapUnit');
--

    ALTER TABLE JIDataType
        RENAME COLUMN maxValue TO max_value;

    CALL SYSPROC.ADMIN_CMD('REORG TABLE JIDataType');