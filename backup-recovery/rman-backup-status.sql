/* =============================================================================
   PURPOSE  : Recent RMAN backup jobs - status, duration and throughput.
              The first thing to check when someone asks "are we covered?"
   VIEWS    : v$rman_backup_job_details
   LICENSE  : None
   RAC      : V$ CORRECT. This view reads the RMAN repository in
              the shared controlfile, so every instance returns identical rows;
              gv$ would duplicate each job once per node.
   PARAMS   : &days_back - how far back to look, e.g. 7
   NOTES    : Retention is bounded by CONTROL_FILE_RECORD_KEEP_TIME (default
              7 days) unless you use a recovery catalog. Watch for status
              'COMPLETED WITH ERRORS' - not a failure, but not a clean backup.
   ============================================================================= */

col status for a25
col input_type for a15
col time_taken for a12
col in_size for a10
col out_size for a10
col rate for a12

SELECT
    j.session_key,
    j.input_type,
    j.status,
    j.start_time,
    j.end_time,
    j.time_taken_display              AS time_taken,
    j.input_bytes_display             AS in_size,
    j.output_bytes_display            AS out_size,
    j.output_bytes_per_sec_display    AS rate
FROM
    v$rman_backup_job_details j
WHERE
    j.start_time > SYSDATE - &days_back
ORDER BY
    j.start_time DESC;
