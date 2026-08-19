/* =============================================================================
   PURPOSE  : Sessions ranked by PGA in use right now. Start here when the
              server is under memory pressure.
   VIEWS    : v$session, v$process
   LICENSE  : None
   RAC      : No (v$ - current instance only; switch to gv$ for all nodes)
   PARAMS   : None
   NOTES    : pga_alloc_mem is what the OS gave the process; pga_used_mem is
              what is actually in use. A large gap means memory is held but idle.
   ============================================================================= */

col sid format 9999
col serial# format 99999
col username for a10
col machine for a20
col program for a25
col sql_id for a13
SELECT
  s.username,
  s.sid,
  s.serial#,
  s.program,
  s.machine,
  s.status,
  s.sql_id,
  p.spid,
  ROUND(p.pga_used_mem/1024/1024,2) AS pga_used_mb,
  ROUND(p.pga_alloc_mem/1024/1024,2) AS pga_alloc_mb
FROM
  v$session s
JOIN
  v$process p
ON
  s.paddr = p.addr
WHERE 
  s.username IS NOT NULL
ORDER BY 
  p.pga_used_mem DESC;