/* =============================================================================
   PURPOSE  : Space used and free per permanent tablespace, ordered by fullest.
   VIEWS    : dba_data_files, dba_free_space
   LICENSE  : None
   RAC      : N/A (dictionary view)
   PARAMS   : None
   NOTES    : Reports current allocated size, NOT autoextend headroom - a
              tablespace at 99% may still have room to grow to maxbytes.
              Excludes TEMP (dba_temp_files) and undo.
   ============================================================================= */

SELECT
    df.tablespace_name,
    ROUND(SUM(df.bytes)/1024/1024/1024,2) AS total_gb,
    ROUND(SUM(df.bytes - NVL(fs.bytes,0))/1024/1024/1024,2) AS used_gb,
    ROUND(SUM(NVL(fs.bytes,0))/1024/1024/1024,2) AS free_gb,
    ROUND((SUM(df.bytes - NVL(fs.bytes,0)) / SUM(df.bytes)) * 100,2) AS pct_used
FROM
    dba_data_files df
LEFT JOIN
    (SELECT tablespace_name, SUM(bytes) bytes
     FROM dba_free_space
     GROUP BY tablespace_name) fs
ON
    df.tablespace_name = fs.tablespace_name
GROUP BY
    df.tablespace_name
ORDER BY
    pct_used DESC;