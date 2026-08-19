/* =============================================================================
   PURPOSE  : DBMS_SCHEDULER jobs running right now, joined to their session so
              you can see the SQL_ID and kill the job's session if needed.
   VIEWS    : dba_scheduler_running_jobs, gv$session
   LICENSE  : None
   RAC      : MIXED - job identity comes from dba_scheduler_running_jobs, which
              is cluster-wide and carries RUNNING_INSTANCE; the session detail
              comes from gv$session. The join MUST match inst_id to
              running_instance, or a job on node 1 will pair with whatever
              session happens to share that SID on node 2.
   PARAMS   : None
   NOTES    : The job columns (owner, job_name, elapsed_time, cpu_used,
              running_instance) live in DBA_SCHEDULER_RUNNING_JOBS, NOT in
              gv$scheduler_running_jobs - that fixed view only exposes
              inst_id, session_id, session_serial_num, job_id, paddr,
              os_process_id and session_stat_cpu. Mixing the two raises
              ORA-00904.
              serial# is taken from gv$session because
              dba_scheduler_running_jobs does not carry it, and you need it for
              maintenance/kill-session.sql.
   ============================================================================= */

col owner for a18
col job_name for a30
col username for a18
col elapsed_minutes for 9999.99

SELECT
    r.owner,
    r.job_name,
    r.running_instance,
    r.session_id                AS sid,
    s.serial#,
    ROUND(EXTRACT(DAY    FROM r.elapsed_time) * 1440
        + EXTRACT(HOUR   FROM r.elapsed_time) * 60
        + EXTRACT(MINUTE FROM r.elapsed_time)
        + EXTRACT(SECOND FROM r.elapsed_time) / 60, 2) AS elapsed_minutes,
    r.cpu_used,
    s.username,
    s.status,
    s.sql_id,
    s.event
FROM
    dba_scheduler_running_jobs r
LEFT JOIN
    gv$session s
ON  s.sid     = r.session_id
AND s.inst_id = r.running_instance
ORDER BY
    r.elapsed_time DESC;
