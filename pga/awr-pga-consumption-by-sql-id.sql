/* =============================================================================
   PURPOSE  : Historical peak PGA per SQL_ID over a date range, from AWR's
              sampled session history. Use to find past memory spikes.
   VIEWS    : dba_hist_active_sess_history, dba_users
   LICENSE  : Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : Yes (instance_number is selected)
   PARAMS   : &FROM_DATE_TIME, &TO_DATE_TIME - format YYYY-MM-DD
   NOTES    : ASH is sampled (1s in memory, 10s persisted to AWR), so short
              spikes can be missed entirely. The rownum < 2000 filter is applied
              BEFORE grouping and is not deterministic - it caps cost but means
              results are a partial sample, not a true ranking.
   ============================================================================= */

SELECT
    u.username,
    s.sql_id,
    s.instance_number,
    ROUND(max(s.pga_alloc_mem) / 1024 / 1024, 2) AS max_pga_alloc_mb,
    s.program
FROM
    DBA_HIST_ACTIVE_SESS_HISTORY s
JOIN
    DBA_USERS u ON u.user_id = s.user_id
WHERE
    sample_time 
    BETWEEN 
    TO_DATE('&FROM_DATE_TIME', 'YYYY-MM-DD') 
    AND 
    TO_DATE('&TO_DATE_TIME', 'YYYY-MM-DD')
    AND 
    rownum < 2000
    AND
    sql_id IS NOT NULL
GROUP BY
    u.username,
    s.sql_id,
    s.instance_number,
    s.program
ORDER BY
    max_pga_alloc_mb DESC;