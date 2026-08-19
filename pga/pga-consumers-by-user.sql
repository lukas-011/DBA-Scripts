/* =============================================================================
   PURPOSE  : PGA rolled up by user and SQL_ID, to spot an app or statement
              running many sessions that each look small individually.
   VIEWS    : gv$session, gv$process
   LICENSE  : None
   RAC      : Per-instance BY DESIGN. gv$ is used to reach every node, but
              totals are grouped by inst_id and never summed across the
              cluster - PGA is host memory, so a cluster-wide total is
              meaningless. 200 GB on node 1 and 5 GB on node 2 is a node 1
              emergency, not a 205 GB cluster-wide condition.
              To look at one node only, add: AND s.inst_id = <n>
   PARAMS   : None
   NOTES    : The inst_id predicate in the join is required: paddr/addr are
              per-instance memory addresses and DO collide across nodes, so
              joining on paddr alone pairs a session on one instance with a
              process on another.
   ============================================================================= */

col username for a20
col sql_id for a13

SELECT
    s.inst_id,
    s.username,
    s.sql_id,
    COUNT(*)                                  AS sessions,
    ROUND(SUM(p.pga_used_mem)/1024/1024,2)    AS total_pga_used_mb,
    ROUND(SUM(p.pga_alloc_mem)/1024/1024,2)   AS total_pga_alloc_mb,
    ROUND(AVG(p.pga_used_mem)/1024/1024,2)    AS avg_pga_used_mb
FROM
    gv$session s
JOIN
    gv$process p
ON  s.paddr   = p.addr
AND s.inst_id = p.inst_id
WHERE
    s.username IS NOT NULL
GROUP BY
    s.inst_id,
    s.username,
    s.sql_id
ORDER BY
    s.inst_id,
    total_pga_used_mb DESC;
