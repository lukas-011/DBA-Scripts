/* =============================================================================
   PURPOSE  : Indexes, partitions and subpartitions left UNUSABLE - usually
              after a direct-path load, a partition exchange, or a table move.
              An unusable index is silently ignored by the optimizer, so this
              shows up as "the query got slow" rather than as an error.
   VIEWS    : dba_indexes, dba_ind_partitions, dba_ind_subpartitions
   LICENSE  : None
   RAC      : N/A - dictionary views, identical from any instance.
   PARAMS   : &owner - schema to check, or % for all
   NOTES    : Generate the rebuilds with maintenance/rebuild-unusable-indexes.sql
              rather than by hand - the syntax differs for partitions and
              subpartitions and is easy to get wrong.
   ============================================================================= */

col owner for a18
col index_name for a30
col segment for a30
col level_type for a14

SELECT owner, index_name, 'INDEX' AS level_type, NULL AS segment, status
FROM   dba_indexes
WHERE  status = 'UNUSABLE'
AND    owner LIKE UPPER('&owner')
UNION ALL
SELECT index_owner, index_name, 'PARTITION', partition_name, status
FROM   dba_ind_partitions
WHERE  status = 'UNUSABLE'
AND    index_owner LIKE UPPER('&owner')
UNION ALL
SELECT index_owner, index_name, 'SUBPARTITION', subpartition_name, status
FROM   dba_ind_subpartitions
WHERE  status = 'UNUSABLE'
AND    index_owner LIKE UPPER('&owner')
ORDER BY 1, 2, 3;
