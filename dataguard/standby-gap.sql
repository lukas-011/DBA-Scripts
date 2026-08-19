/* =============================================================================
   PURPOSE  : Whether the standby is actually keeping up - archive gaps, and
              the state of the redo transport and apply processes.
   VIEWS    : v$archive_gap, gv$managed_standby, v$archived_log, v$database
   LICENSE  : Data Guard (included in Enterprise Edition)
   RAC      : MIXED - gaps are per THREAD#, one thread per primary instance.
              v$archive_gap is controlfile-wide so v$ is correct; process state
              is per-instance so gv$ is required there.
   PARAMS   : None
   NOTES    : Query 1 returning rows is a real gap that will stall apply.
              In query 2, look for process MRP0 with status APPLYING_LOG. No
              MRP0 row at all means managed recovery is not running:
                ALTER DATABASE RECOVER MANAGED STANDBY DATABASE
                  USING CURRENT LOGFILE DISCONNECT FROM SESSION;
   ============================================================================= */

col process for a10
col status for a14
col client_process for a14

/* -----------------------------------------------------------------------
   QUERY 1: Archive gaps (run on the STANDBY) - any row here is a problem
   ----------------------------------------------------------------------- */
SELECT
    thread#,
    low_sequence#,
    high_sequence#,
    high_sequence# - low_sequence# + 1 AS missing_logs
FROM
    v$archive_gap;


/* -----------------------------------------------------------------------
   QUERY 2: Transport and apply processes
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    process,
    status,
    client_process,
    thread#,
    sequence#,
    block#,
    blocks,
    delay_mins
FROM
    gv$managed_standby
WHERE
    status <> 'IDLE'
ORDER BY
    inst_id, process;


/* -----------------------------------------------------------------------
   QUERY 3: Last log received vs last log applied, per thread
   ----------------------------------------------------------------------- */
SELECT
    thread#,
    MAX(CASE WHEN applied = 'YES' THEN sequence# END) AS last_applied_seq,
    MAX(sequence#)                                    AS last_received_seq,
    MAX(sequence#) - MAX(CASE WHEN applied = 'YES'
                              THEN sequence# END)     AS logs_behind
FROM
    v$archived_log
WHERE
    resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
GROUP BY
    thread#
ORDER BY
    thread#;
