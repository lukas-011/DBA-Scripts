/* =============================================================================
   PURPOSE  : GENERATE DBMS_STATS.GATHER_TABLE_STATS calls for tables with
              stale or missing statistics. Prints PL/SQL only - nothing is
              gathered until you run the generated block.
   VIEWS    : dba_tab_statistics
   LICENSE  : None
   RAC      : N/A - dictionary view. The gather itself is database-wide, and
              DEGREE => AUTO_DEGREE can spread parallel slaves across nodes.
   PARAMS   : &owner - schema, or % for all
   NOTES    : Defaults chosen here and why:
                ESTIMATE_PERCENT => AUTO_SAMPLE_SIZE  - the only sensible value
                  on 11g+; a fixed percentage is both slower and less accurate.
                METHOD_OPT => 'FOR ALL COLUMNS SIZE AUTO' - lets Oracle decide
                  which columns get histograms based on observed workload.
                CASCADE => TRUE - gathers index stats at the same time.
                DEGREE => DBMS_STATS.AUTO_DEGREE - parallelism by table size.
              Gathering stats INVALIDATES cursors and can change plans. On a
              busy production system do it in a change window, and consider
              NO_INVALIDATE => FALSE only when you want the new plans at once.
   ============================================================================= */

SET PAGESIZE 0
SET FEEDBACK OFF
SET LINESIZE 200
col gather_stmt for a190

SELECT
    'EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => ''' || owner ||
    ''', tabname => ''' || table_name ||
    ''', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE' ||
    ', method_opt => ''FOR ALL COLUMNS SIZE AUTO''' ||
    ', degree => DBMS_STATS.AUTO_DEGREE, cascade => TRUE);' AS gather_stmt
FROM
    dba_tab_statistics
WHERE
    object_type = 'TABLE'
AND owner LIKE UPPER('&owner')
AND owner NOT IN ('SYS','SYSTEM','XDB','OUTLN','DBSNMP','AUDSYS','WMSYS')
AND (stale_stats = 'YES' OR last_analyzed IS NULL)
ORDER BY
    owner, table_name;

SET PAGESIZE 50
SET FEEDBACK ON
