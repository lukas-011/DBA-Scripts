/* =============================================================================
   PURPOSE  : One-screen morning check. Every row is a named check with an OK /
              WARN / CRITICAL verdict, so it can be eyeballed in five seconds
              or scraped by a monitoring job.
   VIEWS    : gv$instance, v$database, dba_data_files, dba_free_space,
              dba_objects, dba_scheduler_job_run_details, v$archived_log,
              v$recovery_file_dest, gv$session, dba_indexes
   LICENSE  : None - deliberately avoids every dba_hist_* view so this can run
              on an unlicensed database.
   RAC      : Mixed by design - gv$ for per-instance state (instances up,
              blocked sessions), v$ for controlfile-wide facts (archiving,
              FRA). See the RAC section of the top-level README.
   PARAMS   : None
   NOTES    : Thresholds are inline and deliberately conservative. Tune them to
              your environment - an 85% tablespace is an emergency in some
              shops and normal in others.
              Drill into any WARN/CRITICAL with the folder named in the check.
   ============================================================================= */

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
    /* Tablespaces near their autoextend ceiling -------------------------- */
    SELECT 3, 'Tablespace headroom',
           CASE WHEN MAX(pct) >= 95 THEN 'CRITICAL'
                WHEN MAX(pct) >= 85 THEN 'WARN' ELSE 'OK' END,
           CASE WHEN MAX(pct) >= 85
                THEN COUNT(CASE WHEN pct >= 85 THEN 1 END) ||
                     ' tablespace(s) over 85% of max; worst=' ||
                     MAX(tablespace_name) KEEP (DENSE_RANK LAST ORDER BY pct) ||
                     ' at ' || ROUND(MAX(pct),1) || '%'
                ELSE 'worst tablespace at ' || ROUND(MAX(pct),1) || '% of max'
           END
    FROM ( SELECT df.tablespace_name,
                  (SUM(df.bytes) - NVL(MAX(fs.free_bytes),0))
                    / NULLIF(SUM(CASE WHEN df.autoextensible='YES'
                                      THEN GREATEST(df.maxbytes, df.bytes)
                                      ELSE df.bytes END),0) * 100 AS pct
           FROM   dba_data_files df
           LEFT JOIN (SELECT tablespace_name, SUM(bytes) free_bytes
                      FROM dba_free_space GROUP BY tablespace_name) fs
                  ON fs.tablespace_name = df.tablespace_name
           GROUP BY df.tablespace_name )

    UNION ALL
    /* Flash recovery area ------------------------------------------------ */
    SELECT 4, 'FRA usage',
           CASE WHEN NVL(MAX(pct_unreclaimable),0) >= 90 THEN 'CRITICAL'
                WHEN NVL(MAX(pct_unreclaimable),0) >= 75 THEN 'WARN'
                ELSE 'OK' END,
           NVL(TO_CHAR(ROUND(MAX(pct_unreclaimable),1)),'0') ||
           '% used and not reclaimable'
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
