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