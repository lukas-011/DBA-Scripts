-- Selects all datafiles that are less than 30G so they can be resized
col file_name for a60
col sql_stmt for a120
SELECT
    file_name,
    tablespace_name,
    bytes / (1024*1024) as MB,
    'ALTER DATABASE DATAFILE ''' || file_name || ''' RESIZE 30G;' AS sql_stmt
FROM
    dba_data_files
WHERE
    tablespace_name = '&tablespace'
AND
    bytes < 30*1024*1024*1024;