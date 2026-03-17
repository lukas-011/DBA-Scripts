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