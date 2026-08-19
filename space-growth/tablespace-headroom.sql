/* =============================================================================
   PURPOSE  : Real tablespace headroom, distinguishing tablespaces that have a
              genuine ceiling from those set to autoextend without limit.
   VIEWS    : dba_data_files, dba_free_space, dba_tablespaces
   LICENSE  : None
   RAC      : N/A - dictionary views, identical from any instance.
   PARAMS   : None
   NOTES    : Read the AUTOEXTEND column FIRST; it decides which percentage is
              meaningful:
                UNLIMITED - maxbytes is a fiction (32G per smallfile datafile,
                            32T per bigfile). pct_of_max will read ~0 forever
                            and is useless. The real limit is free space on the
                            filesystem or ASM disk group, which the data
                            dictionary CANNOT see - check asm/diskgroup-space.sql
                            or the OS. Watch pct_of_alloc instead: hitting it
                            triggers an autoextend, which fails if the
                            filesystem is full.
                CAPPED    - maxbytes is a real limit. pct_of_max is the number
                            to alert on.
                FIXED     - no autoextend at all. pct_of_alloc IS pct_of_max,
                            and hitting it means ORA-01653.
              Verified on 23ai, where every default tablespace is UNLIMITED and
              a naive pct-of-max check silently never fires.
   ============================================================================= */

col tablespace_name for a26
col autoextend for a10
col contents for a10

SELECT
    df.tablespace_name,
    ts.contents,
    CASE WHEN df.autoextend_files = 0                THEN 'FIXED'
         WHEN df.max_bytes >= 34359721984            THEN 'UNLIMITED'
         ELSE 'CAPPED'
    END                                                              AS autoextend,
    ROUND(df.alloc_bytes/1024/1024/1024, 2)                          AS allocated_gb,
    ROUND((df.alloc_bytes - NVL(fs.free_bytes,0))/1024/1024/1024, 2) AS used_gb,
    ROUND((df.alloc_bytes - NVL(fs.free_bytes,0))
          / NULLIF(df.alloc_bytes,0) * 100, 1)                       AS pct_of_alloc,
    CASE WHEN df.max_bytes < 34359721984
         THEN ROUND(df.max_bytes/1024/1024/1024, 2) END              AS max_gb,
    CASE WHEN df.max_bytes < 34359721984
         THEN ROUND((df.alloc_bytes - NVL(fs.free_bytes,0))
                    / NULLIF(df.max_bytes,0) * 100, 1) END           AS pct_of_max,
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
    NVL(CASE WHEN df.max_bytes < 34359721984
             THEN (df.alloc_bytes - NVL(fs.free_bytes,0)) / NULLIF(df.max_bytes,0) * 100
        END,
        (df.alloc_bytes - NVL(fs.free_bytes,0)) / NULLIF(df.alloc_bytes,0) * 100) DESC;
