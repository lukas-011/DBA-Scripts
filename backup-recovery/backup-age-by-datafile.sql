/* =============================================================================
   PURPOSE  : Newest backup per datafile, so you can spot files that have
              silently dropped out of the backup schedule.
   VIEWS    : v$backup_datafile, v$datafile, v$tablespace
   LICENSE  : None
   RAC      : Yes - v$ is CORRECT here (controlfile-wide, identical on every
              instance; gv$ would multiply rows by node count).
   PARAMS   : &warn_days - flag files not backed up in this many days, e.g. 7
   NOTES    : A datafile in a read-only or offline tablespace legitimately
              stops being backed up - check status before raising an alarm.
              Incremental level 0 counts as a full for restore purposes.
   ============================================================================= */

col file_name for a55
col tablespace_name for a25
col aging for a12

SELECT
    df.file#,
    ts.name                                            AS tablespace_name,
    df.name                                            AS file_name,
    df.status,
    bd.last_backup,
    ROUND(SYSDATE - bd.last_backup, 2)                 AS days_since_backup,
    bd.incremental_level,
    CASE
      WHEN bd.last_backup IS NULL                      THEN 'NEVER'
      WHEN SYSDATE - bd.last_backup > &warn_days       THEN 'STALE'
      ELSE 'OK'
    END                                                AS aging
FROM
    v$datafile df
JOIN
    v$tablespace ts ON ts.ts# = df.ts#
LEFT JOIN
    (SELECT
         file#,
         MAX(completion_time)                          AS last_backup,
         MAX(incremental_level) KEEP (DENSE_RANK LAST ORDER BY completion_time)
                                                       AS incremental_level
     FROM v$backup_datafile
     GROUP BY file#) bd
ON  bd.file# = df.file#
ORDER BY
    bd.last_backup NULLS FIRST;
