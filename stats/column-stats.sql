SELECT
    column_name,
    num_distinct,
    density,
    num_nulls,
    last_analyzed
FROM
    dba_tab_col_statistics
WHERE
    owner = UPPER('&owner')
AND table_name = UPPER('&table_name');