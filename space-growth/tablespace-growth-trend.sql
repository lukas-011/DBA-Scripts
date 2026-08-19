/* =============================================================================
   PURPOSE  : Tablespace growth over time from AWR, with a linear projection of
              days until full. Turns "we are at 80%" into "we have 12 days".
   VIEWS    : dba_hist_tbspc_space_usage, dba_tablespaces, v$tablespace
   LICENSE  : Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : N/A - space usage is database-wide, recorded once per snapshot.
   PARAMS   : &days_back - history to base the trend on, e.g. 30
   NOTES    : Sizes in dba_hist_tbspc_space_usage are in BLOCKS, hence the
              block_size multiplication.
              rtime is a VARCHAR2 in 'MM/DD/YYYY HH24:MI:SS' format, NOT a
              date. It must be converted before ordering - sorting the raw
              string puts '01/15/2026' before '12/31/2025' and silently picks
              the wrong first/last sample.
              The growth rate uses the ACTUAL observed span between the first
              and last sample, not &days_back, so a tablespace with only three
              days of history is not reported as growing eight times slower
              than it is.
              The projection is a naive linear fit: useless for spiky or
              seasonal growth, and misleading if a one-off bulk load happened
              inside the window. Treat it as a triage signal, not a capacity
              plan. Flat or shrinking tablespaces give NULL days.
   ============================================================================= */

col tablespace_name for a28

SELECT
    tablespace_name,
    ROUND(current_used_gb, 2)                              AS current_used_gb,
    ROUND(max_gb, 2)                                       AS max_gb,
    ROUND(observed_days, 1)                                AS observed_days,
    ROUND(growth_gb_per_day, 3)                            AS growth_gb_per_day,
    CASE
      WHEN growth_gb_per_day <= 0 THEN NULL
      ELSE ROUND((max_gb - current_used_gb) / growth_gb_per_day)
    END                                                    AS est_days_until_full
FROM (
    SELECT
        tablespace_name,
        last_used  * block_size / 1024/1024/1024           AS current_used_gb,
        last_max   * block_size / 1024/1024/1024           AS max_gb,
        observed_days,
        CASE WHEN observed_days > 0
             THEN (last_used - first_used) * block_size / 1024/1024/1024
                  / observed_days
        END                                                AS growth_gb_per_day
    FROM (
        SELECT
            ts.name                                                       AS tablespace_name,
            t.block_size,
            MAX(h.tablespace_usedsize) KEEP (DENSE_RANK LAST  ORDER BY h.rtime_dt) AS last_used,
            MIN(h.tablespace_usedsize) KEEP (DENSE_RANK FIRST ORDER BY h.rtime_dt) AS first_used,
            MAX(h.tablespace_maxsize)  KEEP (DENSE_RANK LAST  ORDER BY h.rtime_dt) AS last_max,
            MAX(h.rtime_dt) - MIN(h.rtime_dt)                             AS observed_days
        FROM (
            SELECT
                tablespace_id,
                tablespace_usedsize,
                tablespace_maxsize,
                TO_DATE(rtime, 'MM/DD/YYYY HH24:MI:SS') AS rtime_dt
            FROM   dba_hist_tbspc_space_usage
        ) h
        JOIN   v$tablespace ts   ON ts.ts#            = h.tablespace_id
        JOIN   dba_tablespaces t ON t.tablespace_name = ts.name
        WHERE  h.rtime_dt > SYSDATE - &days_back
        GROUP BY ts.name, t.block_size
    )
)
ORDER BY
    est_days_until_full NULLS LAST;
