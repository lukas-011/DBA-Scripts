/* =============================================================================
   PURPOSE  : Wait time grouped by class, which separates an I/O problem from a
              concurrency problem from a cluster problem in one glance.
   VIEWS    : gv$system_wait_class
   LICENSE  : None
   RAC      : Yes (gv$ - REQUIRED). A high 'Cluster' class here is the cue to
              go to rac/gc-waits.sql.
   PARAMS   : None
   NOTES    : Cumulative since startup. Percentages are within each instance,
              so they sum to 100 per node rather than across the cluster.
   ============================================================================= */

col wait_class for a20

SELECT
    inst_id,
    wait_class,
    total_waits,
    ROUND(time_waited/100, 1)                        AS total_wait_sec,
    ROUND(RATIO_TO_REPORT(time_waited)
          OVER (PARTITION BY inst_id) * 100, 1)      AS pct_of_instance_wait
FROM
    gv$system_wait_class
WHERE
    wait_class <> 'Idle'
ORDER BY
    inst_id, time_waited DESC;
