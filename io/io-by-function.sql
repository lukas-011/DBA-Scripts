/* =============================================================================
   PURPOSE  : I/O broken down by what Oracle was doing - buffer cache reads,
              direct reads, RMAN, DBWR, LGWR. Answers "what is generating all
              this I/O", which per-file statistics cannot.
   VIEWS    : gv$iostat_function
   LICENSE  : None (11g and later)
   RAC      : GV$ REQUIRED - per-instance I/O counters.
   PARAMS   : None
   NOTES    : Cumulative since instance startup. Useful shapes:
                'Direct Reads' dominating   => full scans bypassing the cache,
                                               or parallel query
                'RMAN' during business hours => backups overlapping the workload
                'Buffer Cache Reads' high   => cache too small, or a bad plan
                'LGWR'/'Log Writer' slow    => redo on slow storage, which
                                               stalls every commit
              Not available before 11g.
   ============================================================================= */

col function_name for a26

SELECT
    inst_id,
    function_name,
    small_read_megabytes  + large_read_megabytes  AS read_mb,
    small_write_megabytes + large_write_megabytes AS write_mb,
    small_read_reqs  + large_read_reqs            AS read_reqs,
    small_write_reqs + large_write_reqs           AS write_reqs,
    number_of_waits,
    ROUND(wait_time / NULLIF(number_of_waits, 0), 2) AS avg_wait_ms
FROM
    gv$iostat_function
WHERE
    small_read_megabytes + large_read_megabytes
  + small_write_megabytes + large_write_megabytes > 0
ORDER BY
    inst_id, read_mb + write_mb DESC;
