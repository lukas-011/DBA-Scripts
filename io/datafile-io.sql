/* =============================================================================
   PURPOSE  : Physical I/O per datafile with average service times - finds the
              file, and therefore the storage, that is slow.
   VIEWS    : gv$filestat, v$datafile, v$tablespace, gv$tempstat, v$tempfile
   LICENSE  : None
   RAC      : GV$ REQUIRED for the statistics - each instance does its own I/O
              and counts it separately. v$datafile is joined for names only
              (controlfile-wide, one row per file, so it does not duplicate).
   PARAMS   : None
   NOTES    : The approx_read_mb/approx_write_mb columns assume an 8K block
              size - hence "approx". Scale them for tablespaces created with a
              different block size; the timing columns are unaffected.
              readtim/writetim are in CENTISECONDS, hence the *10 to reach
              milliseconds. Times are only populated when TIMED_STATISTICS is
              TRUE (the default).
              Counters are cumulative since instance startup, so a file that
              was hammered last week still looks busy. For a current view,
              compare two runs a few minutes apart, or use waits/ash-recent.sql.
              Above roughly 20ms average single-block read on flash-backed
              storage, or 10ms on all-flash, suspect the storage rather than
              the query.
   ============================================================================= */

col file_name for a52
col tablespace_name for a24

/* -----------------------------------------------------------------------
   QUERY 1: Datafile I/O, slowest average read first
   ----------------------------------------------------------------------- */
SELECT
    fs.inst_id,
    ts.name                                                AS tablespace_name,
    df.name                                                AS file_name,
    fs.phyrds                                              AS reads,
    fs.phywrts                                             AS writes,
    ROUND(fs.readtim  * 10 / NULLIF(fs.phyrds,  0), 2)     AS avg_read_ms,
    ROUND(fs.writetim * 10 / NULLIF(fs.phywrts, 0), 2)     AS avg_write_ms,
    ROUND(fs.phyblkrd  * 8 / 1024, 1)                      AS approx_read_mb,
    ROUND(fs.phyblkwrt * 8 / 1024, 1)                      AS approx_write_mb
FROM
    gv$filestat fs
JOIN
    v$datafile df   ON df.file# = fs.file#
JOIN
    v$tablespace ts ON ts.ts#   = df.ts#
WHERE
    fs.phyrds > 0
ORDER BY
    avg_read_ms DESC NULLS LAST;


/* -----------------------------------------------------------------------
   QUERY 2: Tempfile I/O - heavy activity here means sorts are spilling
   ----------------------------------------------------------------------- */
SELECT
    ts.inst_id,
    tf.name                                                AS file_name,
    ts.phyrds                                              AS reads,
    ts.phywrts                                             AS writes,
    ROUND(ts.readtim  * 10 / NULLIF(ts.phyrds,  0), 2)     AS avg_read_ms,
    ROUND(ts.writetim * 10 / NULLIF(ts.phywrts, 0), 2)     AS avg_write_ms
FROM
    gv$tempstat ts
JOIN
    v$tempfile tf ON tf.file# = ts.file#
ORDER BY
    ts.inst_id, ts.phyrds DESC;
