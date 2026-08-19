/* =============================================================================
   PURPOSE  : Top SQL by database time over a historical window. The AWR
              counterpart to top-sql-by-elapsed-time.sql - survives cursor
              aging, so it can answer "what was heavy last Tuesday".
   VIEWS    : dba_hist_sqlstat, dba_hist_snapshot, dba_hist_sqltext
   LICENSE  : Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : Yes - deltas are summed across instance_number, because a
              statement's total cost IS cluster-wide. Add instance_number to
              the GROUP BY if you need to know which node ran it.
   PARAMS   : &days_back - window, e.g. 7
              &top_n - rows to return, e.g. 25
   NOTES    : *_delta columns are per-snapshot increments, so summing them over
              the window gives true totals - do NOT use the non-delta columns
              here, they are cumulative since the cursor was loaded.
              Ranked by total elapsed; sort by avg_elapsed_sec instead to find
              individually slow statements rather than frequently-run ones.
   ============================================================================= */

col sql_id for a13
col sql_text for a55 word_wrapped

SELECT * FROM (
    SELECT
        st.sql_id,
        SUM(st.executions_delta)                                           AS execs,
        ROUND(SUM(st.elapsed_time_delta)/1e6, 1)                           AS total_elapsed_sec,
        ROUND(SUM(st.elapsed_time_delta)/1e6
              /GREATEST(SUM(st.executions_delta),1), 4)                    AS avg_elapsed_sec,
        ROUND(SUM(st.cpu_time_delta)/1e6, 1)                               AS total_cpu_sec,
        ROUND(SUM(st.buffer_gets_delta)
              /GREATEST(SUM(st.executions_delta),1))                       AS avg_buffer_gets,
        ROUND(SUM(st.disk_reads_delta)
              /GREATEST(SUM(st.executions_delta),1))                       AS avg_disk_reads,
        COUNT(DISTINCT st.plan_hash_value)                                 AS plans,
        COUNT(DISTINCT st.instance_number)                                 AS on_instances,
        DBMS_LOB.SUBSTR(MIN(t.sql_text), 200, 1)                           AS sql_text
    FROM
        dba_hist_sqlstat st
    JOIN
        dba_hist_snapshot sn
        ON  sn.snap_id         = st.snap_id
        AND sn.instance_number = st.instance_number
        AND sn.dbid            = st.dbid
    LEFT JOIN
        dba_hist_sqltext t
        ON  t.sql_id = st.sql_id
        AND t.dbid   = st.dbid
    WHERE
        sn.begin_interval_time > SYSDATE - &days_back
    AND st.executions_delta > 0
    GROUP BY
        st.sql_id
    ORDER BY
        total_elapsed_sec DESC
)
WHERE ROWNUM <= &top_n;
