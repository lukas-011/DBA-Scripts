/* =============================================================================
   PURPOSE  : Session counts grouped by client machine, to find which host is
              opening the most connections. Catches connection-pool leaks and
              runaway app servers.
   VIEWS    : gv$session
   LICENSE  : None
   RAC      : GV$ REQUIRED - session and process state is per-instance.
   PARAMS   : None
   NOTES    : ACTIVE vs INACTIVE matters more than the total. A machine with
              600 sessions of which 3 are active is an oversized pool; one with
              600 active is a real workload problem.
   ============================================================================= */

col machine for a30
col username for a20

SELECT
    s.machine,
    COUNT(*)                                                     AS total_sessions,
    SUM(CASE WHEN s.status = 'ACTIVE'   THEN 1 ELSE 0 END)       AS active_sessions,
    SUM(CASE WHEN s.status = 'INACTIVE' THEN 1 ELSE 0 END)       AS inactive_sessions,
    COUNT(DISTINCT s.username)                                   AS distinct_users,
    COUNT(DISTINCT s.inst_id)                                    AS instances,
    ROUND(MAX(s.last_call_et)/60,2)                              AS max_idle_minutes
FROM
    gv$session s
WHERE
    s.type = 'USER'
GROUP BY
    s.machine
ORDER BY
    total_sessions DESC;
