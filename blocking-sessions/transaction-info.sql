col inst_id for 99
col sid for 9999
col start_time for a20

SELECT
    s.inst_id,
    s.sid,
    t.start_time,
    t.used_ublk,
    t.used_urec
FROM
    gv$session s
JOIN
    gv$transaction t
ON
    s.taddr = t.addr
AND s.inst_id = t.inst_id
WHERE
    s.sid = &blocker_sid;