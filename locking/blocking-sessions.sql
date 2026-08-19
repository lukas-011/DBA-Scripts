col inst_id for 99
col blocker_sid for 9999
col blocker_serial for 99999
col blocker_user for a12
col blocker_sql for a13
col blocked_sid for 9999
col blocked_user for a12

SELECT
    s1.inst_id,
    s1.sid AS blocker_sid,
    s1.serial# AS blocker_serial,
    s1.username AS blocker_user,
    s1.sql_id AS blocker_sql,
    s2.sid AS blocked_sid,
    s2.username AS blocked_user
FROM
    gv$lock l1
JOIN gv$session s1 
    ON s1.sid = l1.sid 
   AND s1.inst_id = l1.inst_id
JOIN gv$lock l2 
    ON l1.id1 = l2.id1 
   AND l1.id2 = l2.id2
JOIN gv$session s2 
    ON s2.sid = l2.sid
   AND s2.inst_id = l2.inst_id
WHERE
    l1.block = 1
AND l2.request > 0
ORDER BY
    s1.inst_id, s1.sid;