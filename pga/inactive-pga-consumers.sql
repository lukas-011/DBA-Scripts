/* =============================================================================
   PURPOSE  : Idle sessions still holding PGA. These are the cheapest wins when
              you need memory back - nothing is running, but memory is held.
   VIEWS    : gv$session, gv$process
   LICENSE  : None
   RAC      : PER-INSTANCE - gv$ reaches every node, but PGA is
              host memory and does not pool across the cluster. To reclaim
              memory on one specific host, filter to it:
                AND s.inst_id = <n>
   PARAMS   : None
   NOTES    : Feed inst_id/sid/serial# into maintenance/kill-session.sql. Check
              locking/transaction-info.sql first - an idle session may still
              hold an open transaction that would have to roll back.
   ============================================================================= */

col inst_id format 99
col sid format 9999
col serial# format 99999
col username for a10
col machine for a20
col program for a25
col sql_id for a13

SELECT
    s.inst_id,
    s.username,
    s.sid,
    s.serial#,
    s.program,
    s.machine,
    s.status,
    s.sql_id,
    p.spid,
    ROUND(s.last_call_et/60,2)         AS idle_minutes,
    ROUND(p.pga_used_mem/1024/1024,2)  AS pga_used_mb,
    ROUND(p.pga_alloc_mem/1024/1024,2) AS pga_alloc_mb
FROM
    gv$session s
JOIN
    gv$process p
ON  s.paddr   = p.addr
AND s.inst_id = p.inst_id
WHERE
    s.username IS NOT NULL
AND s.status  <> 'ACTIVE'
ORDER BY
    p.pga_used_mem DESC;
