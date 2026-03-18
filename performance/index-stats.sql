SELECT
    index_name,
    num_rows,
    distinct_keys,
    last_analyzed
FROM
    dba_ind_statistics
WHERE
AND table_name = UPPER('&table_name');