/* =============================================================================
   PURPOSE  : The biggest segments in the database. Where the space actually
              went, when a tablespace fills up.
   VIEWS    : dba_segments
   LICENSE  : None
   RAC      : N/A - dictionary view, identical from any instance.
   PARAMS   : &top_n - how many segments to return, e.g. 30
   NOTES    : dba_segments can be slow on databases with very many extents.
              Partitioned objects appear one row per partition - group by
              segment_name to see the object total.
   ============================================================================= */

col owner for a18
col segment_name for a32
col partition_name for a24
col segment_type for a18
col tablespace_name for a24

SELECT * FROM (
    SELECT
        owner,
        segment_name,
        partition_name,
        segment_type,
        tablespace_name,
        ROUND(bytes/1024/1024/1024, 3) AS size_gb,
        extents
    FROM
        dba_segments
    ORDER BY
        bytes DESC
)
WHERE ROWNUM <= &top_n;
