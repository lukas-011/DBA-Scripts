/* =============================================================================
   PURPOSE  : Who is burning TEMP, and how much is left. Run both queries when
              you hit ORA-01652 (unable to extend temp segment).
   VIEWS    : gv$tempseg_usage, gv$session, dba_temp_free_space
   LICENSE  : None
   RAC      : GV$ REQUIRED - session and process state is per-instance.
   PARAMS   : None
   NOTES    : TEMP is shared cluster-wide but consumed per session, so a single
              runaway sort on one node can exhaust it for every node.
   ============================================================================= */

col tablespace for a20
col username for a20
col sql_id for a13
col segtype for a10
col program for a30

/* -----------------------------------------------------------------------
   QUERY 1: TEMP tablespace headroom overall
   ----------------------------------------------------------------------- */
SELECT
    tablespace_name,
    ROUND(tablespace_size/1024/1024/1024, 2)   AS total_gb,
    ROUND(allocated_space/1024/1024/1024, 2)   AS allocated_gb,
    ROUND(free_space/1024/1024/1024, 2)        AS free_gb,
    ROUND(allocated_space/NULLIF(tablespace_size,0)*100, 2) AS pct_allocated
FROM
    dba_temp_free_space
ORDER BY
    pct_allocated DESC;


/* -----------------------------------------------------------------------
   QUERY 2: Sessions currently holding TEMP, largest first
   ----------------------------------------------------------------------- */
SELECT
    tu.inst_id,
    tu.username,
    s.sid,
    s.serial#,
    tu.sql_id,
    tu.tablespace,
    tu.segtype,
    ROUND(tu.blocks * ts.block_size /1024/1024, 2) AS temp_used_mb,
    s.status,
    s.program,
    ROUND(s.last_call_et/60, 2)                    AS minutes_on_call
FROM
    gv$tempseg_usage tu
JOIN
    gv$session s
ON  s.saddr   = tu.session_addr
AND s.inst_id = tu.inst_id
JOIN
    dba_tablespaces ts
ON  ts.tablespace_name = tu.tablespace
ORDER BY
    tu.blocks DESC;
