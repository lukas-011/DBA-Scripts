/* =============================================================================
   PURPOSE  : Oracle's own advice on SGA, PGA and shared pool sizing. Evidence
              for a memory change request, rather than guesswork.
   VIEWS    : gv$sga_target_advice, gv$pga_target_advice, gv$shared_pool_advice
   LICENSE  : None. Requires STATISTICS_LEVEL >= TYPICAL (the default).
   RAC      : PER-INSTANCE - advisories are computed per instance from that
              instance's own workload. Size each node on its own numbers.
   PARAMS   : None
   NOTES    : Read the *_factor columns: 1.0 is the current setting. Look for
              the point where estd_db_time stops falling - beyond it, extra
              memory buys nothing.
              In query 2, estd_overalloc_count > 0 means the PGA target is too
              small for the workload at that size and sorts would spill to
              TEMP. Any row with overallocation is a size you must not choose.
   ============================================================================= */

/* -----------------------------------------------------------------------
   QUERY 1: SGA sizing advice
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    sga_size            AS sga_mb,
    sga_size_factor,
    estd_db_time,
    estd_db_time_factor,
    estd_physical_reads
FROM
    gv$sga_target_advice
ORDER BY
    inst_id, sga_size;


/* -----------------------------------------------------------------------
   QUERY 2: PGA sizing advice - watch estd_overalloc_count
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    ROUND(pga_target_for_estimate/1024/1024) AS pga_target_mb,
    pga_target_factor,
    estd_pga_cache_hit_percentage,
    estd_overalloc_count
FROM
    gv$pga_target_advice
ORDER BY
    inst_id, pga_target_for_estimate;


/* -----------------------------------------------------------------------
   QUERY 3: Shared pool sizing advice
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    shared_pool_size_for_estimate AS shared_pool_mb,
    shared_pool_size_factor,
    estd_lc_time_saved,
    estd_lc_memory_object_hits
FROM
    gv$shared_pool_advice
ORDER BY
    inst_id, shared_pool_size_for_estimate;
