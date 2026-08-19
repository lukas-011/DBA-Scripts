/* =============================================================================
   PURPOSE  : One-screen orientation for a database you have not seen before -
              identity, mode, role, size and instance layout.
   VIEWS    : v$database, gv$instance, dba_data_files, dba_temp_files, v$log
   LICENSE  : None
   RAC      : MIXED - v$database is controlfile-wide (v$ correct),
              gv$instance must be gv$ to enumerate nodes.
   PARAMS   : None
   NOTES    : Check log_mode ARCHIVELOG and database_role before assuming a
              database is a recoverable primary. open_mode READ ONLY WITH
              APPLY means you are on an Active Data Guard standby - which is
              separately licensed.
   ============================================================================= */

col name for a14
col db_unique_name for a20
col platform_name for a32
col open_mode for a22
col database_role for a18

/* -----------------------------------------------------------------------
   QUERY 1: Database identity and mode
   ----------------------------------------------------------------------- */
SELECT
    name,
    db_unique_name,
    dbid,
    created,
    log_mode,
    open_mode,
    database_role,
    protection_mode,
    flashback_on,
    force_logging,
    platform_name
FROM
    v$database;


/* -----------------------------------------------------------------------
   QUERY 2: Instances in the cluster
   ----------------------------------------------------------------------- */
SELECT
    inst_id, instance_name, host_name, version, startup_time, status, thread#
FROM
    gv$instance
ORDER BY
    inst_id;


/* -----------------------------------------------------------------------
   QUERY 3: Total database size
   ----------------------------------------------------------------------- */
SELECT
    'DATA'  AS file_class, COUNT(*) AS files,
    ROUND(SUM(bytes)/1024/1024/1024, 2) AS total_gb
FROM   dba_data_files
UNION ALL
SELECT
    'TEMP', COUNT(*), ROUND(SUM(bytes)/1024/1024/1024, 2)
FROM   dba_temp_files
UNION ALL
SELECT
    'REDO', COUNT(*), ROUND(SUM(bytes * members)/1024/1024/1024, 2)
FROM   v$log;
