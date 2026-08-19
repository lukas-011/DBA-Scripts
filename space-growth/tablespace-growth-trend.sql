/* =============================================================================
   PURPOSE  : Tablespace growth over time from AWR, with a linear projection of
              days until full. Turns "we are at 80%" into "we have 12 days".
   VIEWS    : dba_hist_tbspc_space_usage, dba_tablespaces, v$tablespace
   LICENSE  : Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : N/A - space usage is database-wide, recorded once per snapshot.
   PARAMS   : &days_back - history to base the trend on, e.g. 30
   NOTES    : Sizes in dba_hist_tbspc_space_usage are in BLOCKS, hence the
              block_size multiplication.
              The projection is a naive linear fit over the window: it is
              useless for spiky or seasonal growth and will mislead if a big
              one-off load happened inside the window. Treat it as a triage
              signal, not a capacity plan. Negative growth gives NULL days.
   ============================================================================= */

col tablespace_name for a28

SELECT
    tablespace_name,
    ROUND(current_used_gb, 2)                              AS current_used_gb,
    ROUND(max_gb, 2)                                       AS max_gb,
    ROUND(growth_gb_per_day, 3)                            AS growth_gb_per_day,
    CASE
      WHEN growth_gb_per_day <= 0 THEN NULL
      ELSE ROUND((max_gb - current_used_gb) / growth_gb_per_day)
    END                                                    AS est_days_until_full
FROM (
    SELECT
        ts.name                                            AS tablespace_name,
        MAX(h.tablespace_usedsize) KEEP (DENSE_RANK LAST ORDER BY h.rtime)
            * t.block_size / 1024/1024/1024                AS current_used_gb,
        MAX(h.tablespace_maxsize) KEEP (DENSE_RANK LAST ORDER BY h.rtime)
            * t.block_size / 1024/1024/1024                AS max_gb,
        (MAX(h.tablespace_usedsize) KEEP (DENSE_RANK LAST  ORDER BY h.rtime) -
         MAX(h.tablespace_usedsize) KEEP (DENSE_RANK FIRST ORDER BY h.rtime))
            * t.block_size / 1024/1024/1024
            / GREATEST(&days_back, 1)                      AS growth_gb_per_day
    FROM   dba_hist_tbspc_space_usage h
    JOIN   v$tablespace ts   ON ts.ts#            = h.tablespace_id
    JOIN   dba_tablespaces t ON t.tablespace_name = ts.name
    WHERE  TO_DATE(h.rtime, 'MM/DD/YYYY HH24:MI:SS') > SYSDATE - &days_back
    GROUP BY ts.name, t.block_size
)
ORDER BY
    est_days_until_full NULLS LAST;
