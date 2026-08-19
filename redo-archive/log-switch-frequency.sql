/* =============================================================================
   PURPOSE  : Redo log switches per day and peak hour, per thread. The standard
              evidence for "our redo logs are undersized".
   VIEWS    : v$log_history
   LICENSE  : None
   RAC      : Yes - broken out by THREAD# because each instance switches its
              own redo independently. v$ not gv$: log history lives in the
              shared controlfile and already contains every thread.
   PARAMS   : &days_back - history window, e.g. 7
   NOTES    : Rule of thumb: more than 4-6 switches/hour under normal load
              means the online redo logs are too small. peak_hour_switches is
              the number that matters - a quiet daily average hides a batch
              window that switches 40 times in an hour.
   ============================================================================= */

col day for a12

SELECT
    thread#,
    day,
    SUM(switches)              AS total_switches,
    ROUND(SUM(switches)/24, 1) AS avg_per_hour,
    MAX(switches)              AS peak_hour_switches
FROM (
    SELECT
        thread#,
        TO_CHAR(first_time, 'YYYY-MM-DD') AS day,
        TO_CHAR(first_time, 'HH24')       AS hr,
        COUNT(*)                          AS switches
    FROM   v$log_history
    WHERE  first_time > SYSDATE - &days_back
    GROUP BY
        thread#,
        TO_CHAR(first_time, 'YYYY-MM-DD'),
        TO_CHAR(first_time, 'HH24')
)
GROUP BY
    thread#, day
ORDER BY
    day DESC, thread#;
