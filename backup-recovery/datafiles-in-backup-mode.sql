/* =============================================================================
   PURPOSE  : Datafiles left in hot-backup mode. A file stuck in BEGIN BACKUP
              logs full block images and will flood the archive destination -
              a classic 3am page after a backup script died halfway.
   VIEWS    : v$backup, v$datafile
   LICENSE  : None
   RAC      : Yes - v$ is CORRECT (backup state is database-wide in the
              controlfile, not per-instance).
   PARAMS   : None
   NOTES    : Any row returned needs action. Clear with
                ALTER DATABASE DATAFILE '<name>' END BACKUP;
              or ALTER DATABASE END BACKUP; for all of them at once.
   ============================================================================= */

col file_name for a60

SELECT
    b.file#,
    d.name          AS file_name,
    b.status,
    b.change#,
    b.time          AS backup_started,
    ROUND((SYSDATE - b.time) * 24, 2) AS hours_stuck
FROM
    v$backup b
JOIN
    v$datafile d ON d.file# = b.file#
WHERE
    b.status = 'ACTIVE'
ORDER BY
    b.time;
