col owner for a12
col job_name for a25
col status for a10
col elapsed_minutes for 999.99

SELECT
    r.owner,
    r.job_name,
    r.session_id AS sid,
    r.session_serial_num AS serial#,
    r.running_instance,
    r.elapsed_time/60 AS elapsed_minutes,
    r.cpu_used,
    s.username,
    s.status,
    s.sql_id
FROM
    gv$scheduler_running_jobs r
JOIN
    gv$session s
    ON r.session_id = s.sid
   AND r.session_serial_num = s.serial#
   AND r.running_instance = s.inst_id
ORDER BY
    r.elapsed_time DESC;