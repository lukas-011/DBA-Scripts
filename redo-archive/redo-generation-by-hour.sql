/* =============================================================================
   PURPOSE  : Redo bytes generated per hour from AWR history. Use to correlate
              a slowdown with a batch job, or to size standby bandwidth.
   VIEWS    : dba_hist_sysstat, dba_hist_snapshot
   LICENSE  : Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : N/A - AWR view. Broken out by instance_number, since each node generates
              its own redo.
   PARAMS   : &days_back - history window, e.g. 7
   NOTES    : dba_hist_sysstat holds cumulative counters, so the per-snapshot
              delta comes from LAG. Partitioning by startup_time restarts the
              window at each instance bounce; the delta_bytes > 0 filter then
              discards the reset row rather than reporting a negative spike.
   ============================================================================= */

col hour for a16

SELECT
    instance_number,
    TO_CHAR(snap_time, 'YYYY-MM-DD HH24')            AS hour,
    ROUND(SUM(delta_bytes)/1024/1024/1024, 3)        AS redo_gb,
    ROUND(SUM(delta_bytes)/1024/1024, 1)             AS redo_mb
FROM (
    SELECT
        st.instance_number,
        sn.begin_interval_time                       AS snap_time,
        st.value - LAG(st.value) OVER (PARTITION BY st.instance_number,
                                                    sn.startup_time
                                       ORDER BY st.snap_id)  AS delta_bytes
    FROM   dba_hist_sysstat st
    JOIN   dba_hist_snapshot sn
           ON  sn.snap_id         = st.snap_id
           AND sn.instance_number = st.instance_number
           AND sn.dbid            = st.dbid
    WHERE  st.stat_name = 'redo size'
    AND    sn.begin_interval_time > SYSDATE - &days_back
)
WHERE delta_bytes > 0
GROUP BY
    instance_number,
    TO_CHAR(snap_time, 'YYYY-MM-DD HH24')
ORDER BY
    hour DESC, instance_number;
