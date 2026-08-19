/* =============================================================================
   PURPOSE  : Session distribution across nodes. Detects a broken load balance,
              which is usually a service or client-side TNS problem.
   VIEWS    : gv$session, gv$instance
   LICENSE  : None
   RAC      : Yes (gv$ - REQUIRED)
   PARAMS   : None
   NOTES    : Perfectly even distribution is not the goal - services are often
              deliberately pinned to a subset of nodes. Check
              rac/service-placement.sql before treating an imbalance as a bug.
   ============================================================================= */

col instance_name for a16
col host_name for a28
col service_name for a30

/* -----------------------------------------------------------------------
   QUERY 1: Totals per instance
   ----------------------------------------------------------------------- */
SELECT
    i.inst_id,
    i.instance_name,
    i.host_name,
    COUNT(s.sid)                                             AS total_sessions,
    SUM(CASE WHEN s.status = 'ACTIVE' THEN 1 ELSE 0 END)     AS active_sessions,
    ROUND(RATIO_TO_REPORT(COUNT(s.sid)) OVER () * 100, 1)    AS pct_of_cluster
FROM
    gv$instance i
LEFT JOIN
    gv$session s
ON  s.inst_id = i.inst_id
AND s.type    = 'USER'
GROUP BY
    i.inst_id, i.instance_name, i.host_name
ORDER BY
    i.inst_id;


/* -----------------------------------------------------------------------
   QUERY 2: Service by instance - where each service is actually connected
   ----------------------------------------------------------------------- */
SELECT
    s.service_name,
    s.inst_id,
    COUNT(*)                                             AS sessions,
    SUM(CASE WHEN s.status = 'ACTIVE' THEN 1 ELSE 0 END) AS active_sessions
FROM
    gv$session s
WHERE
    s.type = 'USER'
GROUP BY
    s.service_name, s.inst_id
ORDER BY
    s.service_name, s.inst_id;
