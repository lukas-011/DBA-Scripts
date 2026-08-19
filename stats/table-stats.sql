col stale_stats for a5

SELECT
    owner,
    table_name,
    num_rows,
    blocks,
    last_analyzed,
    stale_stats,
    sample_size
FROM
    dba_tab_statistics
WHERE
    owner = UPPER('&owner')
AND table_name = UPPER('&table_name');