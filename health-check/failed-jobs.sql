/* =============================================================================
   PURPOSE  : Scheduler jobs that failed recently, plus jobs that are broken or
              disabled. Silent job failure is one of the most common ways a
              database quietly stops being maintained.
   VIEWS    : dba_scheduler_job_run_details, dba_scheduler_jobs
   LICENSE  : None
   RAC      : N/A - dictionary views; the scheduler is cluster-wide. Query 1
              shows which instance actually ran each job.
   PARAMS   : &days_back - window, e.g. 7
   NOTES    : A job with failure_count > 0 but state SCHEDULED is retrying. A
              job in state BROKEN has given up and will not run again until
              re-enabled: EXEC DBMS_SCHEDULER.ENABLE('<owner>.<job_name>');
   ============================================================================= */

col owner for a18
col job_name for a32
col error_detail for a60 word_wrapped
col state for a12

/* -----------------------------------------------------------------------
   QUERY 1: Failed runs in the window
   ----------------------------------------------------------------------- */
SELECT
    owner,
    job_name,
    log_date,
    status,
    error#,
    run_duration,
    instance_id,
    SUBSTR(additional_info, 1, 200) AS error_detail
FROM
    dba_scheduler_job_run_details
WHERE
    log_date > SYSDATE - &days_back
AND status <> 'SUCCEEDED'
ORDER BY
    log_date DESC;


/* -----------------------------------------------------------------------
   QUERY 2: Jobs currently broken or disabled
   ----------------------------------------------------------------------- */
SELECT
    owner,
    job_name,
    state,
    enabled,
    failure_count,
    last_start_date,
    next_run_date
FROM
    dba_scheduler_jobs
WHERE
    (state = 'BROKEN' OR enabled = 'FALSE' OR failure_count > 0)
AND owner NOT IN ('SYS','SYSTEM')
ORDER BY
    failure_count DESC, owner, job_name;
