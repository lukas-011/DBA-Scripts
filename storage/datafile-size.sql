/* =============================================================================
   PURPOSE  : Find datafiles under 30G in a tablespace and GENERATE the ALTER
              statements to resize them to 30G.
   VIEWS    : dba_data_files
   LICENSE  : None
   RAC      : N/A (dictionary view)
   PARAMS   : &tablespace - exact name, UPPERCASE (not case-folded)
   NOTES    : This script only prints DDL - nothing is changed until you run the
              generated statements. Review them first: RESIZE below a file's
              high-water mark fails, and the 30G target is hardcoded.
   ============================================================================= */

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