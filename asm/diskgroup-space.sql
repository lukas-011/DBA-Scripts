/* =============================================================================
   PURPOSE  : ASM disk group capacity. USABLE_FILE_MB is the only number that
              matters - it is the space you can actually use after allowing for
              mirroring and for surviving a disk failure.
   VIEWS    : gv$asm_diskgroup
   LICENSE  : None (ASM is included with the database licence)
   RAC      : GV$ REQUIRED - ASM runs one instance per node. Disk groups are
              shared so capacity agrees across nodes, but mount state does NOT:
              a disk group dismounted on one node only is a real and common
              failure, and gv$ is how you see it.
   PARAMS   : None
   NOTES    : Run from the ASM instance for full detail. From a database
              instance these views are populated but sparser.
              A NEGATIVE usable_file_mb is an emergency: there is not enough
              free space to fully rebalance after losing a disk, so a single
              disk failure would take the disk group down. Free_mb can look
              healthy while usable_file_mb is negative - that is exactly the
              trap this script exists to catch.
              required_mirror_free_mb is what ASM reserves for that rebuild.
   ============================================================================= */

col name for a24
col state for a12
col type for a10
col verdict for a26

SELECT
    inst_id,
    name,
    state,
    type,
    ROUND(total_mb/1024, 2)                    AS total_gb,
    ROUND(free_mb/1024, 2)                     AS free_gb,
    ROUND(required_mirror_free_mb/1024, 2)     AS req_mirror_free_gb,
    ROUND(usable_file_mb/1024, 2)              AS usable_gb,
    ROUND((total_mb - free_mb)/NULLIF(total_mb,0)*100, 1) AS pct_used,
    offline_disks,
    CASE
      WHEN state <> 'MOUNTED'      THEN 'NOT MOUNTED'
      WHEN usable_file_mb < 0      THEN 'CRITICAL: cannot rebalance'
      WHEN offline_disks > 0       THEN 'DISKS OFFLINE'
      WHEN (total_mb - free_mb)/NULLIF(total_mb,0)*100 > 90 THEN 'over 90% used'
      ELSE 'ok'
    END                                        AS verdict
FROM
    gv$asm_diskgroup
ORDER BY
    inst_id, name;
