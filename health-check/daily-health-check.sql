/* =============================================================================
   PURPOSE  : One-screen morning check. Every row is a named check with an OK /
              WARN / CRITICAL verdict, so it can be eyeballed in five seconds
              or scraped by a monitoring job.
   VIEWS    : gv$instance, v$database, dba_data_files, dba_free_space,
              dba_objects, dba_scheduler_job_run_details, v$archived_log,
              v$recovery_file_dest, gv$session, dba_indexes
   LICENSE  : None - deliberately avoids every dba_hist_* view so this can run
              on an unlicensed database.
   RAC      : MIXED - gv$ for per-instance state (instances up,
              blocked sessions), v$ for controlfile-wide facts (archiving,
              FRA). See the RAC section of the top-level README.
   PARAMS   : None
   NOTES    : Thresholds are inline and deliberately conservative. Tune them to
              your environment - an 85% tablespace is an emergency in some
              shops and normal in others.
              Drill into any WARN/CRITICAL with the folder named in the check.
              SQLBLANKLINES is required: this is ONE statement containing blank
              lines between its UNION ALL branches, and a default SQL*Plus
              session treats a blank line as a statement terminator - which
              breaks the query apart with SP2-0042. Verified against 23ai.
   ============================================================================= */

SET SQLBLANKLINES ON

col check_name for a28
col status for a10
col detail for a62

SELECT check_name, status, detail FROM (

    /* Instances up ------------------------------------------------------ */
    SELECT 1 AS ord, 'Instances up' AS check_name,
           'OK' AS status,
           COUNT(*) || ' instance(s) open: ' ||
           LISTAGG(instance_name, ', ') WITHIN GROUP (ORDER BY inst_id) AS detail
    FROM   gv$instance WHERE status = 'OPEN'

    UNION ALL
    /* Archivelog mode --------------------------------------------------- */
    SELECT 2, 'Archivelog mode',
           CASE WHEN log_mode = 'ARCHIVELOG' THEN 'OK' ELSE 'CRITICAL' END,
           'log_mode=' || log_mode || '  role=' || database_role ||
           '  open_mode=' || open_mode
    FROM   v$database

    UNION ALL
    /* Tablespace headroom ------------------------------------------------
       Only tablespaces with a REAL ceiling (fixed size, or capped autoextend)
       are graded. Two wrong ways to do this, both verified on 23ai.
       First, measuring against maxbytes when autoextend is UNLIMITED reads
       ~0% forever, so the check never fires. Second, measuring UNLIMITED
       against allocated size reads ~99% forever, because Oracle deliberately
       keeps datafiles full and extends on demand, so the check cries wolf
       every morning.
       An UNLIMITED tablespace is bounded by filesystem or ASM free space,
       which SQL cannot see. It is counted and named as unassessable rather
       than being given a misleading verdict.
       -------------------------------------------------------------------- */
    SELECT 3, 'Tablespace headroom',
           CASE WHEN capped_cnt = 0                THEN 'N/A'
                WHEN worst_capped_pct >= 95        THEN 'CRITICAL'
                WHEN worst_capped_pct >= 85        THEN 'WARN'
                ELSE 'OK' END,
           CASE WHEN capped_cnt = 0
                THEN 'all ' || unlimited_cnt ||
                     ' tablespace(s) autoextend UNLIMITED - check filesystem/ASM'
                ELSE worst_capped_name || ' at ' || ROUND(worst_capped_pct,1) ||
                     '% of its limit' ||
                     CASE WHEN unlimited_cnt > 0
                          THEN ' (' || unlimited_cnt || ' more UNLIMITED, not assessable)'
                     END
           END
    FROM ( SELECT COUNT(CASE WHEN has_real_limit = 'Y' THEN 1 END)      AS capped_cnt,
                  COUNT(CASE WHEN has_real_limit = 'N' THEN 1 END)      AS unlimited_cnt,
                  MAX(CASE WHEN has_real_limit = 'Y' THEN pct END)      AS worst_capped_pct,
                  MAX(CASE WHEN has_real_limit = 'Y' THEN tablespace_name END)
                    KEEP (DENSE_RANK LAST ORDER BY CASE WHEN has_real_limit='Y' THEN pct END
                          NULLS FIRST)                                  AS worst_capped_name
           FROM ( SELECT tablespace_name,
                  CASE WHEN max_bytes < 34359721984 THEN 'Y' ELSE 'N' END AS has_real_limit,
                  (alloc_bytes - free_bytes)
                    / NULLIF(CASE WHEN max_bytes < 34359721984
                                  THEN max_bytes ELSE alloc_bytes END, 0) * 100 AS pct
           FROM ( SELECT df.tablespace_name,
                         SUM(df.bytes) AS alloc_bytes,
                         SUM(CASE WHEN df.autoextensible='YES'
                                  THEN GREATEST(df.maxbytes, df.bytes)
                                  ELSE df.bytes END) AS max_bytes,
                         NVL(MAX(fs.free_bytes),0) AS free_bytes
                  FROM   dba_data_files df
                  LEFT JOIN (SELECT tablespace_name, SUM(bytes) free_bytes
                             FROM dba_free_space GROUP BY tablespace_name) fs
                         ON fs.tablespace_name = df.tablespace_name
                  GROUP BY df.tablespace_name ) ) )

    UNION ALL
    /* Flash recovery area ------------------------------------------------
       v$recovery_file_dest is EMPTY when db_recovery_file_dest is unset.
       Reporting OK on no rows would be a check that silently never runs, so
       the empty case is reported explicitly instead.
       -------------------------------------------------------------------- */
    SELECT 4, 'FRA usage',
           CASE WHEN COUNT(*) = 0                  THEN 'NOT SET'
                WHEN MAX(pct_unreclaimable) >= 90  THEN 'CRITICAL'
                WHEN MAX(pct_unreclaimable) >= 75  THEN 'WARN'
                ELSE 'OK' END,
           CASE WHEN COUNT(*) = 0
                THEN 'db_recovery_file_dest not configured - check not run'
                ELSE ROUND(MAX(pct_unreclaimable),1) ||
                     '% used and not reclaimable'
           END
    FROM ( SELECT (space_used - space_reclaimable)/NULLIF(space_limit,0)*100
                    AS pct_unreclaimable
           FROM   v$recovery_file_dest )

    UNION ALL
    /* Archiving actually happening --------------------------------------- */
    SELECT 5, 'Last archived log',
           CASE WHEN MAX(completion_time) IS NULL             THEN 'WARN'
                WHEN MAX(completion_time) < SYSDATE - 1       THEN 'WARN'
                ELSE 'OK' END,
           'most recent archived log: ' ||
           NVL(TO_CHAR(MAX(completion_time), 'YYYY-MM-DD HH24:MI'), 'none found')
    FROM   v$archived_log
    WHERE  completion_time > SYSDATE - 7

    UNION ALL
    /* Invalid objects ---------------------------------------------------- */
    SELECT 6, 'Invalid objects',
           CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'WARN' END,
           COUNT(*) || ' invalid object(s)'
    FROM   dba_objects WHERE status = 'INVALID'

    UNION ALL
    /* Unusable indexes --------------------------------------------------- */
    SELECT 7, 'Unusable indexes',
           CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'WARN' END,
           COUNT(*) || ' unusable index(es)'
    FROM   dba_indexes WHERE status = 'UNUSABLE'

    UNION ALL
    /* Failed scheduler jobs ---------------------------------------------- */
    SELECT 8, 'Failed jobs (24h)',
           CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'WARN' END,
           COUNT(*) || ' failed job run(s) in the last 24h'
    FROM   dba_scheduler_job_run_details
    WHERE  log_date > SYSDATE - 1 AND status <> 'SUCCEEDED'

    UNION ALL
    /* Blocked sessions --------------------------------------------------- */
    SELECT 9, 'Blocked sessions',
           CASE WHEN COUNT(*) = 0 THEN 'OK'
                WHEN COUNT(*) > 5 THEN 'CRITICAL' ELSE 'WARN' END,
           COUNT(*) || ' session(s) currently blocked'
    FROM   gv$session
    WHERE  blocking_session IS NOT NULL

    UNION ALL
    /* Long-running sessions ---------------------------------------------- */
    SELECT 10, 'Long active sessions',
           CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'WARN' END,
           COUNT(*) || ' session(s) active for over 2 hours'
    FROM   gv$session
    WHERE  status = 'ACTIVE' AND type = 'USER' AND last_call_et > 7200

) ORDER BY ord;
