/* =============================================================================
   PURPOSE  : Real tablespace headroom, accounting for autoextend. This is the
              number worth alerting on - storage/tablespace-utilization.sql
              reports current allocation, which reads as 99% full for a healthy
              autoextending tablespace.
   VIEWS    : dba_data_files, dba_free_space, dba_tablespaces
   LICENSE  : None
   RAC      : N/A - dictionary views, identical from any instance.
   PARAMS   : None
   NOTES    : max_gb is the ceiling the tablespace can autoextend to; for a
              non-autoextensible file that is simply its current size. A
              bigfile tablespace or a file at MAXSIZE UNLIMITED is capped by
              the 32G/128T datafile limit, not by the value shown here.
              pct_used_of_max is the one to page on.
   ============================================================================= */

col tablespace_name for a28

SELECT
    df.tablespace_name,
    ts.contents,
    ROUND(df.alloc_bytes/1024/1024/1024, 2)                        AS allocated_gb,
    ROUND(df.max_bytes/1024/1024/1024, 2)                          AS max_gb,
    ROUND((df.alloc_bytes - NVL(fs.free_bytes,0))/1024/1024/1024, 2) AS used_gb,
    ROUND((df.max_bytes - (df.alloc_bytes - NVL(fs.free_bytes,0)))
          /1024/1024/1024, 2)                                      AS free_to_grow_gb,
    ROUND((df.alloc_bytes - NVL(fs.free_bytes,0))
          / NULLIF(df.max_bytes,0) * 100, 2)                       AS pct_used_of_max,
    df.autoextend_files,
    df.total_files
FROM
    (SELECT
         tablespace_name,
         SUM(bytes)                                              AS alloc_bytes,
         SUM(CASE WHEN autoextensible = 'YES'
                  THEN GREATEST(maxbytes, bytes) ELSE bytes END) AS max_bytes,
         SUM(CASE WHEN autoextensible = 'YES' THEN 1 ELSE 0 END) AS autoextend_files,
         COUNT(*)                                                AS total_files
     FROM   dba_data_files
     GROUP BY tablespace_name) df
LEFT JOIN
    (SELECT tablespace_name, SUM(bytes) AS free_bytes
     FROM   dba_free_space
     GROUP BY tablespace_name) fs
ON  fs.tablespace_name = df.tablespace_name
JOIN
    dba_tablespaces ts ON ts.tablespace_name = df.tablespace_name
ORDER BY
    pct_used_of_max DESC;
