/* =============================================================================
   PURPOSE  : SGA layout and current component sizes. The counterpart to the
              pga/ scripts - together they account for all Oracle memory on
              the host.
   VIEWS    : gv$sgainfo, gv$sga_dynamic_components, gv$memory_dynamic_components
   LICENSE  : None
   RAC      : PER-INSTANCE - the SGA is per-instance host memory. Never sum
              these across nodes; read them one instance at a time, the same
              way as the pga/ scripts.
   PARAMS   : None
   NOTES    : Query 2 shows components Oracle has resized automatically. A high
              oper_count means memory is thrashing between components, which
              usually means SGA_TARGET is too small for the workload.
              Under AMM (MEMORY_TARGET set) query 3 is the authoritative view
              and SGA/PGA are traded against each other automatically; under
              ASMM (SGA_TARGET set, MEMORY_TARGET 0) query 3 returns nothing.
   ============================================================================= */

col name for a34
col component for a34
col resizeable for a12

/* -----------------------------------------------------------------------
   QUERY 1: SGA breakdown
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    name,
    ROUND(bytes/1024/1024, 1) AS size_mb,
    resizeable
FROM
    gv$sgainfo
ORDER BY
    inst_id, bytes DESC;


/* -----------------------------------------------------------------------
   QUERY 2: Dynamic components and how often Oracle has resized them
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    component,
    ROUND(current_size/1024/1024, 1)        AS current_mb,
    ROUND(min_size/1024/1024, 1)            AS min_mb,
    ROUND(max_size/1024/1024, 1)            AS max_mb,
    ROUND(user_specified_size/1024/1024, 1) AS user_set_mb,
    oper_count,
    last_oper_type,
    last_oper_time
FROM
    gv$sga_dynamic_components
WHERE
    current_size > 0
ORDER BY
    inst_id, current_size DESC;


/* -----------------------------------------------------------------------
   QUERY 3: Automatic Memory Management components (only if MEMORY_TARGET set)
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    component,
    ROUND(current_size/1024/1024, 1) AS current_mb,
    ROUND(min_size/1024/1024, 1)     AS min_mb,
    ROUND(max_size/1024/1024, 1)     AS max_mb,
    oper_count,
    last_oper_type
FROM
    gv$memory_dynamic_components
WHERE
    current_size > 0
ORDER BY
    inst_id, current_size DESC;
