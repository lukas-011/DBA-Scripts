/* =============================================================================
   PURPOSE  : Global cache (cluster) waits - the cost of nodes shipping blocks
              to each other. High values here mean the workload is not
              partitioned well across instances.
   VIEWS    : gv$system_event, gv$sysstat
   LICENSE  : None
   RAC      : GV$ REQUIRED
   PARAMS   : None
   NOTES    : 'gc cr block busy' and 'gc buffer busy acquire/release' point at
              hot blocks contended across nodes - often a sequence without
              CACHE/NOORDER, or an index right-hand-side hotspot.
              Average times above ~10ms for a 'gc ... 2-way' event suggest an
              interconnect problem rather than an application one.
   ============================================================================= */

col event for a40
col name for a45

/* -----------------------------------------------------------------------
   QUERY 1: Cluster-class wait events by instance
   ----------------------------------------------------------------------- */
SELECT
    e.inst_id,
    e.event,
    e.total_waits,
    ROUND(e.time_waited_micro/1e6, 1)                              AS total_wait_sec,
    ROUND(e.time_waited_micro/1e6/NULLIF(e.total_waits,0)*1000, 2) AS avg_wait_ms
FROM
    gv$system_event e
WHERE
    e.wait_class = 'Cluster'
AND e.total_waits > 0
ORDER BY
    e.inst_id, e.time_waited_micro DESC;


/* -----------------------------------------------------------------------
   QUERY 2: Global cache block transfer counters
   ----------------------------------------------------------------------- */
SELECT
    s.inst_id,
    s.name,
    s.value
FROM
    gv$sysstat s
WHERE
    s.name IN ('gc cr blocks received',
               'gc cr blocks served',
               'gc current blocks received',
               'gc current blocks served',
               'gc local grants',
               'gc remote grants')
ORDER BY
    s.inst_id, s.name;
