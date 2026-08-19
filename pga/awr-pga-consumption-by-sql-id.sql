/* =============================================================================
   PURPOSE  : Historical peak PGA per SQL_ID over a date range, from AWR's
              sampled session history. Use to find past memory spikes.
   VIEWS    : dba_hist_active_sess_history, dba_users
   LICENSE  : Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : N/A - AWR view. instance_number distinguishes nodes, and rows are
              kept per instance because PGA is host memory - see the pga/
              scripts for why a cluster-wide PGA total is meaningless.
   PARAMS   : &FROM_DATE_TIME, &TO_DATE_TIME - format YYYY-MM-DD
              &top_n - rows to return, e.g. 50
   NOTES    : ASH is sampled (1s in memory, 10s persisted to AWR), so short
              spikes can be missed entirely.
              The row cap is applied AFTER grouping and sorting. An earlier
              version had ROWNUM < 2000 in the WHERE clause, which Oracle
              applies before GROUP BY and ORDER BY - that capped cost but made
              the result an arbitrary partial sample rather than a true
              ranking. If this query is too slow over a wide window, narrow
              the date range rather than reinstating a ROWNUM predicate.
   ============================================================================= */

col username for a20
col sql_id for a13
col program for a30

SELECT * FROM (
    SELECT
        u.username,
        s.sql_id,
        s.instance_number,
        s.program,
        ROUND(MAX(s.pga_alloc_mem) / 1024 / 1024, 2) AS max_pga_alloc_mb,
        COUNT(*)                                     AS ash_samples
    FROM
        dba_hist_active_sess_history s
    JOIN
        dba_users u ON u.user_id = s.user_id
    WHERE
        s.sample_time BETWEEN TO_DATE('&FROM_DATE_TIME', 'YYYY-MM-DD')
                          AND TO_DATE('&TO_DATE_TIME',   'YYYY-MM-DD')
    AND s.sql_id IS NOT NULL
    GROUP BY
        u.username,
        s.sql_id,
        s.instance_number,
        s.program
    ORDER BY
        max_pga_alloc_mb DESC
)
WHERE ROWNUM <= &top_n;
