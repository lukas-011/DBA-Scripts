/* =============================================================================
   PURPOSE  : Active Session History for the last N minutes - what was actually
              consuming the database during a recent incident. The single most
              useful diagnostic script when someone says "it was slow at 2pm".
   VIEWS    : gv$active_session_history
   LICENSE  : Diagnostics Pack REQUIRED
   RAC      : GV$ REQUIRED - ASH buffers are per-instance)
   PARAMS   : &minutes_back - window to analyse, e.g. 30
   NOTES    : ASH samples once per second per active session, so each sample
              row represents roughly one second of database time. That is why
              COUNT(*) is a usable proxy for seconds spent.
              In-memory ASH only holds the last hour or so; past that, query
              dba_hist_active_sess_history instead.
   ============================================================================= */

col event for a38
col wait_class for a14
col username for a18
col sql_id for a13

/* -----------------------------------------------------------------------
   QUERY 1: Top wait events in the window
   ----------------------------------------------------------------------- */
SELECT * FROM (
    SELECT
        NVL(ash.event, 'ON CPU')                          AS event,
        NVL(ash.wait_class, 'CPU')                        AS wait_class,
        COUNT(*)                                          AS est_seconds,
        ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100, 1) AS pct_db_time,
        COUNT(DISTINCT ash.session_id)                    AS distinct_sessions
    FROM
        gv$active_session_history ash
    WHERE
        ash.sample_time > SYSTIMESTAMP - NUMTODSINTERVAL(&minutes_back, 'MINUTE')
    GROUP BY
        NVL(ash.event, 'ON CPU'), NVL(ash.wait_class, 'CPU')
    ORDER BY
        est_seconds DESC
)
WHERE ROWNUM <= 20;


/* -----------------------------------------------------------------------
   QUERY 2: Top SQL in the window, by database time
   ----------------------------------------------------------------------- */
SELECT * FROM (
    SELECT
        ash.sql_id,
        ash.sql_plan_hash_value,
        u.username,
        COUNT(*)                                          AS est_seconds,
        ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100, 1) AS pct_db_time,
        COUNT(DISTINCT ash.inst_id)                       AS on_instances
    FROM
        gv$active_session_history ash
    LEFT JOIN
        dba_users u ON u.user_id = ash.user_id
    WHERE
        ash.sample_time > SYSTIMESTAMP - NUMTODSINTERVAL(&minutes_back, 'MINUTE')
    AND ash.sql_id IS NOT NULL
    GROUP BY
        ash.sql_id, ash.sql_plan_hash_value, u.username
    ORDER BY
        est_seconds DESC
)
WHERE ROWNUM <= 20;
