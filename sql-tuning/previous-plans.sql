/* =============================================================================
   PURPOSE  : SQL_ID plan history and performance comparison - find out when a
              plan changed and whether the new plan is actually worse.
   VIEWS    : dba_hist_sqlstat, dba_hist_snapshot, DBMS_XPLAN.DISPLAY_AWR,
              DBMS_XPLAN.DISPLAY_CURSOR
   LICENSE  : Diagnostics Pack REQUIRED for queries 1-3; query 4 is free
   RAC      : MIXED - AWR queries 1-3 join on instance_number and so cover the
              whole cluster; query 4 reads the local cursor cache only and
              returns the plan for the instance you are connected to.
   PARAMS   : &sql_id - target SQL_ID, e.g. 'abcd1234efgh5'
              &plan_hash_value - for query 3, taken from query 1 or 2
   =============================================================================

   Queries 1-3 use the AWR views (DBA_HIST_* and DBMS_XPLAN.DISPLAY_AWR):
     - Requires the Oracle Diagnostics Pack license.
     - History depth = your AWR retention setting (default 8 days; check/change
       with DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS).

   Query 4 uses V$SQL (cursor cache):
     - No extra license needed.
     - Only shows plans still resident in the shared pool right now — plans
       get aged out, sometimes within hours, so this is a short-term view.
   ============================================================================= */

/* -----------------------------------------------------------------------
   QUERY 1: Plan-hash performance by AWR snapshot, ordered by date
   One row per (snapshot, plan_hash_value). Shows exactly when a plan
   change happened and how that plan behaved in each time window.
   ----------------------------------------------------------------------- */
SELECT
    sn.begin_interval_time                                                   AS snap_time,
    st.plan_hash_value,
    st.executions_delta                                                      AS execs,
    ROUND(st.elapsed_time_delta / GREATEST(st.executions_delta,1) / 1000, 2) AS avg_elapsed_ms,
    ROUND(st.cpu_time_delta     / GREATEST(st.executions_delta,1) / 1000, 2) AS avg_cpu_ms,
    ROUND(st.buffer_gets_delta  / GREATEST(st.executions_delta,1), 0)        AS avg_buffer_gets,
    ROUND(st.disk_reads_delta   / GREATEST(st.executions_delta,1), 0)        AS avg_disk_reads,
    ROUND(st.rows_processed_delta / GREATEST(st.executions_delta,1), 0)      AS avg_rows,
    st.optimizer_cost
FROM   dba_hist_sqlstat   st
JOIN   dba_hist_snapshot  sn
       ON sn.snap_id = st.snap_id AND sn.instance_number = st.instance_number
WHERE  st.sql_id = '&sql_id'
AND    st.executions_delta > 0
ORDER  BY sn.begin_interval_time, st.plan_hash_value;


/* -----------------------------------------------------------------------
   QUERY 2: One row per plan hash value — lifespan + aggregate performance
   Rolls query 1 up so you can see, at a glance, which plan is actually
   the better performer overall and how long each one has been in use.
   ----------------------------------------------------------------------- */
SELECT
    st.plan_hash_value,
    MIN(sn.begin_interval_time)                                                     AS first_seen,
    MAX(sn.begin_interval_time)                                                     AS last_seen,
    SUM(st.executions_delta)                                                        AS total_execs,
    ROUND(SUM(st.elapsed_time_delta)/GREATEST(SUM(st.executions_delta),1)/1000, 2)   AS avg_elapsed_ms,
    ROUND(SUM(st.cpu_time_delta)/GREATEST(SUM(st.executions_delta),1)/1000, 2)       AS avg_cpu_ms,
    ROUND(SUM(st.buffer_gets_delta)/GREATEST(SUM(st.executions_delta),1), 0)         AS avg_buffer_gets,
    ROUND(SUM(st.disk_reads_delta)/GREATEST(SUM(st.executions_delta),1), 0)          AS avg_disk_reads
FROM   dba_hist_sqlstat   st
JOIN   dba_hist_snapshot  sn
       ON sn.snap_id = st.snap_id AND sn.instance_number = st.instance_number
WHERE  st.sql_id = '&sql_id'
AND    st.executions_delta > 0
GROUP  BY st.plan_hash_value
ORDER  BY first_seen;


/* -----------------------------------------------------------------------
   QUERY 3: Render the actual plan steps for ONE plan hash value (AWR)
   Swap in a plan_hash_value from Query 1 or 2. 'ALLSTATS LAST' adds
   estimated-vs-actual row counts when that data was captured.
   ----------------------------------------------------------------------- */

SELECT *
FROM   TABLE(DBMS_XPLAN.DISPLAY_AWR('&sql_id', &plan_hash_value, NULL, 'ALLSTATS LAST'));


/* -----------------------------------------------------------------------
   QUERY 4: Same, but for a plan still sitting in the cursor cache
   ----------------------------------------------------------------------- */
SELECT *
FROM   TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', NULL, 'ALLSTATS LAST'));