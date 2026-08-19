/* =============================================================================
   PURPOSE  : Buffer cache efficiency and the sizing advisory - whether making
              the cache bigger would actually reduce physical reads.
   VIEWS    : gv$sysstat, gv$db_cache_advice, v$parameter (for db_block_size,
              which cannot differ between instances)
   LICENSE  : None. The advisory needs STATISTICS_LEVEL >= TYPICAL (the
              default); it returns no rows if set to BASIC.
   RAC      : PER-INSTANCE - each instance has its own buffer cache, sized
              against its own host memory. Never sum across nodes.
   PARAMS   : None
   NOTES    : Treat the hit ratio in query 1 as context, NOT as a target. A
              99% hit ratio is routinely produced by a badly tuned query doing
              millions of buffer gets against a small hot table - tuning that
              query LOWERS the ratio while making the database faster. Use
              waits/ash-recent.sql to find real problems; use this to size.
              Query 2 is the useful one: size_factor 1.0 is your current cache.
              If estd_physical_read_factor barely falls as size_factor rises,
              more buffer cache will not help and the memory is better spent
              on PGA.
   ============================================================================= */

col metric for a34
col name for a24

/* -----------------------------------------------------------------------
   QUERY 1: Logical vs physical reads since startup
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    MAX(CASE WHEN name = 'db block gets'    THEN value END)      AS db_block_gets,
    MAX(CASE WHEN name = 'consistent gets'  THEN value END)      AS consistent_gets,
    MAX(CASE WHEN name = 'physical reads'   THEN value END)      AS physical_reads,
    ROUND((1 - MAX(CASE WHEN name = 'physical reads' THEN value END)
             / NULLIF(MAX(CASE WHEN name = 'db block gets'   THEN value END)
                    + MAX(CASE WHEN name = 'consistent gets' THEN value END), 0)
          ) * 100, 2)                                            AS hit_ratio_pct
FROM
    gv$sysstat
WHERE
    name IN ('db block gets','consistent gets','physical reads')
GROUP BY
    inst_id
ORDER BY
    inst_id;


/* -----------------------------------------------------------------------
   QUERY 2: Cache sizing advisory - would a bigger cache help?
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    name,
    size_for_estimate                AS cache_mb,
    size_factor,
    estd_physical_read_factor,
    estd_physical_reads
FROM
    gv$db_cache_advice
WHERE
    advice_status = 'ON'
AND block_size = (SELECT value FROM v$parameter WHERE name = 'db_block_size')
ORDER BY
    inst_id, size_for_estimate;
