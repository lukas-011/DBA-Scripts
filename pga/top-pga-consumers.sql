/* =============================================================================
   PURPOSE  : Sessions ranked by PGA in use right now. Start here when the
              server is under memory pressure.
   VIEWS    : gv$session, gv$process
   LICENSE  : None
   RAC      : PER-INSTANCE - gv$ reaches every node, but PGA is
              host memory and does not pool across the cluster. inst_id is the
              first column for that reason. When you are chasing memory
              pressure on one specific host, filter to it:
                AND s.inst_id = <n>
   PARAMS   : None
   NOTES    : pga_alloc_mem is what the OS gave the process; pga_used_mem is
              what is actually in use. A large gap means memory is held but idle.
              The inst_id predicate in the join is required: paddr/addr are
              per-instance memory addresses and DO collide across nodes, so
              joining on paddr alone returns rows pairing a session on one
              instance with a process on another.
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
ORDER BY
    p.pga_used_mem DESC;
