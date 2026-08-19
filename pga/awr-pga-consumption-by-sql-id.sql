SELECT
    u.username,
    s.sql_id,
    s.instance_number,
    ROUND(max(s.pga_alloc_mem) / 1024 / 1024, 2) AS max_pga_alloc_mb,
    s.program,
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