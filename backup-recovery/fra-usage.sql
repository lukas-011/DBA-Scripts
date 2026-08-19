/* =============================================================================
   PURPOSE  : Flash Recovery Area capacity and what is filling it. A full FRA
              hangs the database - archiver stuck, no new transactions.
   VIEWS    : v$recovery_file_dest, v$recovery_area_usage
   LICENSE  : None
   RAC      : V$ CORRECT - (the FRA is shared storage; every instance
              reports the same numbers, gv$ would just duplicate them).
   PARAMS   : None
   NOTES    : Watch RECLAIMABLE, not used. An FRA at 95% used but 80%
              reclaimable is healthy - Oracle frees those files on demand. An
              FRA at 85% used with 0% reclaimable is an emergency.
              On older versions v$recovery_area_usage is named
              v$flash_recovery_area_usage.
   ============================================================================= */

col name for a55
col file_type for a25

/* -----------------------------------------------------------------------
   QUERY 1: Overall FRA capacity
   ----------------------------------------------------------------------- */
SELECT
    name,
    ROUND(space_limit/1024/1024/1024, 2)                          AS limit_gb,
    ROUND(space_used/1024/1024/1024, 2)                           AS used_gb,
    ROUND(space_reclaimable/1024/1024/1024, 2)                    AS reclaimable_gb,
    ROUND(space_used/NULLIF(space_limit,0)*100, 2)                AS pct_used,
    ROUND((space_used - space_reclaimable)
          /NULLIF(space_limit,0)*100, 2)                          AS pct_used_unreclaimable,
    number_of_files
FROM
    v$recovery_file_dest;


/* -----------------------------------------------------------------------
   QUERY 2: Breakdown by file type - what is actually consuming it
   ----------------------------------------------------------------------- */
SELECT
    file_type,
    percent_space_used,
    percent_space_reclaimable,
    number_of_files
FROM
    v$recovery_area_usage
WHERE
    number_of_files > 0
ORDER BY
    percent_space_used DESC;
