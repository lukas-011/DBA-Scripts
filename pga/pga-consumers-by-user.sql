/* =============================================================================
   PURPOSE  : PGA rolled up by user and SQL_ID, to spot an app or statement
              running many sessions that each look small individually.
   VIEWS    : v$session, v$process
   LICENSE  : None
   RAC      : No (v$ - current instance only; switch to gv$ for all nodes)
   PARAMS   : None
   ============================================================================= */

col sid format 9999
col serial# format 99999
col username for a10
col sql_id for a13
SELECT
    s.username,
    s.sql_id,
    ROUND(SUM(p.pga_used_mem)/1024/1024,2) AS total_pga_mb
FROM
    v$session s
JOIN
    v$process p
ON
    s.paddr = p.addr
WHERE
    s.username IS NOT NULL
GROUP BY
    s.username,
    s.sql_id
ORDER BY
    total_pga_mb DESC;