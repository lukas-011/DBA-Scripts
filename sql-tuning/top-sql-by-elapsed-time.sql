/* =============================================================================
   PURPOSE  : SQL ranked by total elapsed time in the cursor cache - the
              heaviest statements running right now.
   VIEWS    : gv$sqlarea
   LICENSE  : None (cursor cache, not AWR)
   RAC      : GV$ REQUIRED - totals are summed across instances, because a
              statement's cost to the database IS cluster-wide. Add sa.inst_id
              to the SELECT and GROUP BY to see which node ran it.
   PARAMS   : &top_n - how many statements to return, e.g. 25
   NOTES    : Cursor cache only. Statements aged out of the shared pool are
              gone, so this is a short-term view - for history that survives
              aging use the AWR equivalent in sql-tuning/awr-top-sql.sql.
              Ranked by TOTAL elapsed time, so a fast statement executed
              millions of times outranks a slow one run twice. That is usually
              what you want; sort by avg_elapsed_sec for the other question.
   ============================================================================= */

col sql_id for a13
col parsing_schema_name for a20
col sql_text for a60 word_wrapped

SELECT * FROM (
    SELECT
        sa.sql_id,
        MIN(sa.parsing_schema_name)                                      AS parsing_schema_name,
        COUNT(DISTINCT sa.plan_hash_value)                               AS plans,
        SUM(sa.executions)                                               AS executions,
        ROUND(SUM(sa.elapsed_time)/1e6, 2)                               AS total_elapsed_sec,
        ROUND(SUM(sa.elapsed_time)/1e6/GREATEST(SUM(sa.executions),1),4) AS avg_elapsed_sec,
        ROUND(SUM(sa.cpu_time)/1e6, 2)                                   AS total_cpu_sec,
        ROUND(SUM(sa.buffer_gets)/GREATEST(SUM(sa.executions),1))        AS avg_buffer_gets,
        ROUND(SUM(sa.disk_reads)/GREATEST(SUM(sa.executions),1))         AS avg_disk_reads,
        MAX(sa.last_active_time)                                         AS last_active,
        MIN(sa.sql_text)                                                 AS sql_text
    FROM
        gv$sqlarea sa
    WHERE
        sa.executions > 0
    GROUP BY
        sa.sql_id
    ORDER BY
        total_elapsed_sec DESC
)
WHERE ROWNUM <= &top_n;
