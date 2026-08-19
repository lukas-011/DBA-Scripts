/* =============================================================================
   PURPOSE  : Long-running operations still in flight, with % complete and ETA.
              Covers full scans, RMAN, index builds, gather-stats, data pump.
   VIEWS    : gv$session_longops
   LICENSE  : None
   RAC      : Yes (gv$ - all instances)
   PARAMS   : None
   NOTES    : Only operations Oracle can estimate appear here. Rows persist
              briefly after completion; the sofar <> totalwork filter drops them.
   ============================================================================= */

SELECT
    lo.inst_id,
    lo.sid,
    lo.serial#,
    lo.opname,
    lo.target,
    lo.sofar,
    lo.totalwork,
    ROUND(lo.sofar / NULLIF(lo.totalwork, 0) * 100, 2) AS pct_complete,
    lo.elapsed_seconds,
    lo.time_remaining,
    lo.sql_id,
    lo.username,
    lo.message
FROM
    gv$session_longops lo
WHERE
    lo.totalwork > 0
    AND lo.sofar <> lo.totalwork
ORDER BY
    lo.time_remaining DESC,
    lo.inst_id;