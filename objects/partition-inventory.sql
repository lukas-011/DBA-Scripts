/* =============================================================================
   PURPOSE  : Partitioned table inventory - partition counts, sizes, and the
              maintenance question that matters most: is the newest partition
              far enough in the future?
   VIEWS    : dba_part_tables, dba_tab_partitions, dba_segments
   LICENSE  : Reading these views is free, but the PARTITIONING OPTION is
              separately licensed. If rows come back, you are using it - check
              that against your contract with config/feature-usage.sql.
   RAC      : N/A - dictionary views, identical from any instance.
   PARAMS   : &owner - schema, or % for all
   NOTES    : Query 2 is the one that prevents outages. A range-partitioned
              table whose highest partition boundary is in the past will start
              rejecting inserts with ORA-14400 (inserted partition key does not
              map to any partition) unless it has a MAXVALUE partition or
              INTERVAL partitioning.
              high_value is a LONG, which cannot be filtered or compared in
              SQL - it is shown for eyeballing only. That is a limitation of
              the data dictionary, not of this script.
   ============================================================================= */

col owner for a18
col table_name for a32
col partition_name for a28
col partitioning_type for a14
col high_value for a40

/* -----------------------------------------------------------------------
   QUERY 1: Partitioned tables, size and partition count
   ----------------------------------------------------------------------- */
SELECT
    pt.owner,
    pt.table_name,
    pt.partitioning_type,
    pt.subpartitioning_type,
    pt.partition_count,
    pt.interval,
    ROUND(sg.total_bytes/1024/1024/1024, 2) AS total_gb
FROM
    dba_part_tables pt
LEFT JOIN
    (SELECT owner, segment_name, SUM(bytes) AS total_bytes
     FROM   dba_segments
     WHERE  segment_type LIKE 'TABLE%'
     GROUP BY owner, segment_name) sg
ON  sg.owner        = pt.owner
AND sg.segment_name = pt.table_name
WHERE
    pt.owner LIKE UPPER('&owner')
AND pt.owner NOT IN ('SYS','SYSTEM','AUDSYS','WMSYS','SYSMAN')
ORDER BY
    sg.total_bytes DESC NULLS LAST;


/* -----------------------------------------------------------------------
   QUERY 2: Highest partition per table - check the boundary is in the future
   ----------------------------------------------------------------------- */
SELECT
    tp.table_owner AS owner,
    tp.table_name,
    tp.partition_name,
    tp.partition_position,
    tp.high_value,
    tp.num_rows,
    tp.last_analyzed
FROM
    dba_tab_partitions tp
JOIN
    (SELECT table_owner, table_name, MAX(partition_position) AS max_pos
     FROM   dba_tab_partitions
     GROUP BY table_owner, table_name) m
ON  m.table_owner = tp.table_owner
AND m.table_name  = tp.table_name
AND m.max_pos     = tp.partition_position
WHERE
    tp.table_owner LIKE UPPER('&owner')
AND tp.table_owner NOT IN ('SYS','SYSTEM','AUDSYS','WMSYS','SYSMAN')
ORDER BY
    tp.table_owner, tp.table_name;
