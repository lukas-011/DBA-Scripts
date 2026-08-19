/* =============================================================================
   PURPOSE  : Tables whose optimizer statistics are stale or missing, with the
              volume of DML behind that staleness. Decides what actually needs
              a gather rather than re-gathering everything.
   VIEWS    : dba_tab_statistics, dba_tab_modifications
   LICENSE  : None
   RAC      : N/A - dictionary views, identical from any instance.
   PARAMS   : &owner - schema, or % for all
   NOTES    : Oracle marks stats stale at roughly 10% row change. The
              pct_changed column here is computed from dba_tab_modifications,
              which is flushed periodically - so it lags by a few minutes and
              can read low right after a big load. Force a flush with:
                EXEC DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;
              Generate the gather calls with maintenance/gather-stats.sql.
   ============================================================================= */

col owner for a18
col table_name for a32
col stale_stats for a6

SELECT
    ts.owner,
    ts.table_name,
    ts.num_rows,
    ts.last_analyzed,
    ts.stale_stats,
    NVL(m.inserts,0) + NVL(m.updates,0) + NVL(m.deletes,0)  AS dml_since_gather,
    ROUND((NVL(m.inserts,0) + NVL(m.updates,0) + NVL(m.deletes,0))
          / NULLIF(ts.num_rows,0) * 100, 1)                 AS pct_changed,
    CASE WHEN ts.last_analyzed IS NULL THEN 'NEVER GATHERED' END AS note
FROM
    dba_tab_statistics ts
LEFT JOIN
    dba_tab_modifications m
ON  m.table_owner   = ts.owner
AND m.table_name    = ts.table_name
AND NVL(m.partition_name, '~') = NVL(ts.partition_name, '~')
WHERE
    ts.object_type = 'TABLE'
AND ts.owner LIKE UPPER('&owner')
AND ts.owner NOT IN ('SYS','SYSTEM','XDB','OUTLN','DBSNMP','AUDSYS','WMSYS')
AND (ts.stale_stats = 'YES' OR ts.last_analyzed IS NULL)
ORDER BY
    pct_changed DESC NULLS LAST;
