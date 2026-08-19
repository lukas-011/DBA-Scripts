/* =============================================================================
   PURPOSE  : GENERATE the ALTER ... REBUILD statements for every unusable
              index, partition and subpartition. Prints DDL only.
   VIEWS    : dba_indexes, dba_ind_partitions, dba_ind_subpartitions
   LICENSE  : None. ONLINE rebuild requires Enterprise Edition - drop the
              ONLINE keyword on Standard Edition.
   RAC      : N/A - dictionary views. The rebuild itself runs cluster-wide.
   PARAMS   : &owner - schema, or % for all
   NOTES    : The three forms differ and are easy to get wrong by hand, which
              is the point of generating them:
                ALTER INDEX x REBUILD;
                ALTER INDEX x REBUILD PARTITION p;
                ALTER INDEX x REBUILD SUBPARTITION sp;
              A subpartitioned index reports its parent partition as unusable
              too, so rebuild at the SUBPARTITION level and the partition
              clears itself - running both wastes a full rebuild.
              ONLINE avoids locking the base table but is slower and needs
              space for the journal.
   ============================================================================= */

SET PAGESIZE 0
SET FEEDBACK OFF
col rebuild_stmt for a110

SELECT 'ALTER INDEX ' || owner || '.' || index_name || ' REBUILD ONLINE;' AS rebuild_stmt
FROM   dba_indexes
WHERE  status = 'UNUSABLE' AND owner LIKE UPPER('&owner')
UNION ALL
SELECT 'ALTER INDEX ' || index_owner || '.' || index_name ||
       ' REBUILD PARTITION ' || partition_name || ' ONLINE;'
FROM   dba_ind_partitions
WHERE  status = 'UNUSABLE' AND index_owner LIKE UPPER('&owner')
UNION ALL
SELECT 'ALTER INDEX ' || index_owner || '.' || index_name ||
       ' REBUILD SUBPARTITION ' || subpartition_name || ' ONLINE;'
FROM   dba_ind_subpartitions
WHERE  status = 'UNUSABLE' AND index_owner LIKE UPPER('&owner');

SET PAGESIZE 50
SET FEEDBACK ON
