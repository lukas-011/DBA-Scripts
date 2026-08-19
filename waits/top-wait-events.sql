/* =============================================================================
   PURPOSE  : Cumulative wait events since instance startup, ranked by time
              waited. Shows where the database spends its time overall.
   VIEWS    : gv$system_event
   LICENSE  : None
   RAC      : GV$ REQUIRED - each instance accumulates its own waits)
   PARAMS   : &top_n - how many events to return, e.g. 20
   NOTES    : These are totals SINCE STARTUP, so they are dominated by whatever
              happened days ago and are near-useless for diagnosing a problem
              happening right now. For that use waits/ash-recent.sql, which
              windows to the last few minutes.
   ============================================================================= */

col event for a40
col wait_class for a15

SELECT * FROM (
    SELECT
        e.inst_id,
        e.event,
        e.wait_class,
        e.total_waits,
        ROUND(e.time_waited_micro/1e6, 1)                              AS total_wait_sec,
        ROUND(e.time_waited_micro/1e6/NULLIF(e.total_waits,0)*1000, 2) AS avg_wait_ms,
        e.total_timeouts
    FROM
        gv$system_event e
    WHERE
        e.wait_class <> 'Idle'
    ORDER BY
        e.time_waited_micro DESC
)
WHERE ROWNUM <= &top_n;
