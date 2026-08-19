/* =============================================================================
   PURPOSE  : Data Pump jobs - running, stopped, and orphaned. Orphaned jobs
              leave master tables behind that consume space and block the job
              name from being reused.
   VIEWS    : dba_datapump_jobs, dba_datapump_sessions, gv$session
   LICENSE  : None
   RAC      : MIXED - dba_datapump_* are dictionary views covering the whole
              cluster; gv$session is joined to show which node each worker is
              actually running on.
   PARAMS   : None
   NOTES    : A job in state NOT RUNNING with 0 attached sessions is ORPHANED -
              the client died and left the master table. It will never resume.
              Clean it up by dropping the master table, which is the job name
              in the owner's schema:
                DROP TABLE <owner>.<job_name> PURGE;
              Verify it is genuinely orphaned first: a job that is merely
              detached can be resumed with impdp/expdp ATTACH=<job_name>.
   ============================================================================= */

col owner_name for a18
col job_name for a30
col operation for a12
col job_mode for a14
col state for a16
col username for a18

/* -----------------------------------------------------------------------
   QUERY 1: All Data Pump jobs, orphans flagged
   ----------------------------------------------------------------------- */
SELECT
    j.owner_name,
    j.job_name,
    j.operation,
    j.job_mode,
    j.state,
    j.degree,
    j.attached_sessions,
    j.datapump_sessions,
    CASE WHEN j.state = 'NOT RUNNING' AND NVL(j.attached_sessions,0) = 0
         THEN 'ORPHANED - see NOTES' END AS verdict
FROM
    dba_datapump_jobs j
ORDER BY
    j.owner_name, j.job_name;


/* -----------------------------------------------------------------------
   QUERY 2: Sessions attached to running jobs, and where they run
   ----------------------------------------------------------------------- */
SELECT
    ds.owner_name,
    ds.job_name,
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.status,
    s.sql_id,
    ROUND(s.last_call_et/60, 1) AS minutes_on_call
FROM
    dba_datapump_sessions ds
JOIN
    gv$session s ON s.saddr = ds.saddr
ORDER BY
    ds.owner_name, ds.job_name, s.inst_id;
