/* =============================================================================
   PURPOSE  : Queries running longer than the undo retention window - the
              population at risk of ORA-01555, before it happens.
   VIEWS    : gv$session, gv$undostat, gv$sql
   LICENSE  : None
   RAC      : GV$ REQUIRED - retention is tuned per instance, so the risk
              threshold differs by node.
   PARAMS   : None
   NOTES    : The comparison is deliberately per-instance: a query on node 2 is
              at risk against node 2's tuned retention, not the cluster's
              lowest. Both come from gv$ and are matched on inst_id.
              A query appearing here has not failed - it is running longer than
              undo is currently guaranteed to be kept, so it WOULD fail if the
              blocks it needs get overwritten. Sustained appearances mean the
              undo tablespace is undersized for the reporting workload, or the
              query needs tuning.
   ============================================================================= */

col username for a18
col sql_id for a13
col program for a28
col verdict for a22

SELECT
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.sql_id,
    s.last_call_et                          AS running_sec,
    u.tuned_retention_sec,
    s.program,
    CASE WHEN s.last_call_et > u.tuned_retention_sec
         THEN 'AT RISK OF ORA-01555' ELSE 'ok' END AS verdict
FROM
    gv$session s
JOIN
    (SELECT inst_id, MAX(tuned_undoretention) AS tuned_retention_sec
     FROM   gv$undostat
     WHERE  begin_time > SYSDATE - 1
     GROUP BY inst_id) u
ON  u.inst_id = s.inst_id
WHERE
    s.status = 'ACTIVE'
AND s.type   = 'USER'
AND s.last_call_et > u.tuned_retention_sec
ORDER BY
    s.last_call_et DESC;
