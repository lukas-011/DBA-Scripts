/* =============================================================================
   PURPOSE  : Missing archived-log sequences per thread. Any gap here is a hard
              stop for point-in-time recovery past that point.
   VIEWS    : v$archived_log
   LICENSE  : None
   RAC      : V$ CORRECT - and the script most often got WRONG on RAC. Each
              instance is its own redo THREAD# with its own independent
              sequence numbering, so gaps must be detected per thread (the
              PARTITION BY below). Comparing sequences across threads invents
              gaps that do not exist.
              v$ not gv$: the controlfile log record is shared, so every
              instance already sees every thread.
   PARAMS   : &days_back - window to check, e.g. 3
   NOTES    : deleted='NO' filter: a log deleted after being backed up is not a
              recovery gap. dest_id=1 keeps one row per sequence when you
              archive to several destinations.
   ============================================================================= */

SELECT *
FROM (
    SELECT
        thread#,
        prev_seq + 1                     AS gap_starts_at,
        sequence# - 1                    AS gap_ends_at,
        sequence# - prev_seq - 1         AS missing_count,
        prev_time                        AS last_good_log_time,
        completion_time                  AS next_log_time
    FROM (
        SELECT
            al.thread#,
            al.sequence#,
            al.completion_time,
            LAG(al.sequence#)       OVER (PARTITION BY al.thread# ORDER BY al.sequence#) AS prev_seq,
            LAG(al.completion_time) OVER (PARTITION BY al.thread# ORDER BY al.sequence#) AS prev_time
        FROM   v$archived_log al
        WHERE  al.completion_time > SYSDATE - &days_back
        AND    al.deleted  = 'NO'
        AND    al.archived = 'YES'
        AND    al.dest_id  = 1
    )
)
WHERE missing_count > 0
ORDER BY thread#, gap_starts_at;
