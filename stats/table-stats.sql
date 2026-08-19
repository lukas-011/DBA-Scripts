/* =============================================================================
   PURPOSE  : Table-level optimizer statistics, including whether they are stale.
   VIEWS    : dba_tab_statistics
   LICENSE  : None
   RAC      : N/A (dictionary view)
   PARAMS   : &owner, &table_name - both case-insensitive
   NOTES    : Returns a row per partition/subpartition on partitioned tables;
              the global row has partition_name IS NULL.
   ============================================================================= */

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