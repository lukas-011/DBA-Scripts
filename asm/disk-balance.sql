/* =============================================================================
   PURPOSE  : ASM disks per group - failgroup layout, imbalance, and I/O
              errors. Run after adding storage or when a rebalance looks stuck.
   VIEWS    : gv$asm_disk, gv$asm_diskgroup
   LICENSE  : None (ASM is included with the database licence)
   RAC      : GV$ REQUIRED - see diskgroup-space.sql. Run from an ASM instance
              for full path and failgroup detail.
   PARAMS   : None
   NOTES    : Any non-zero read_errs or write_errs means a failing disk -
              act on it before ASM drops the disk and forces a rebalance.
              Disks within a group should be close to the same size and close
              to the same pct_used. A wide spread in pct_used means a
              rebalance has not completed:
                ALTER DISKGROUP <name> REBALANCE POWER <n>;
              Check progress in gv$asm_operation.
              header_status of CANDIDATE or FORMER means the disk is visible to
              ASM but not part of any group.
   ============================================================================= */

col diskgroup for a20
col disk_name for a26
col failgroup for a18
col path for a42
col mount_status for a12

SELECT
    d.inst_id,
    g.name                                     AS diskgroup,
    d.name                                     AS disk_name,
    d.failgroup,
    d.mount_status,
    d.header_status,
    d.mode_status,
    d.state,
    ROUND(d.total_mb/1024, 2)                  AS total_gb,
    ROUND(d.free_mb/1024, 2)                   AS free_gb,
    ROUND((d.total_mb - d.free_mb)/NULLIF(d.total_mb,0)*100, 1) AS pct_used,
    d.read_errs,
    d.write_errs,
    d.path
FROM
    gv$asm_disk d
LEFT JOIN
    gv$asm_diskgroup g
ON  g.group_number = d.group_number
AND g.inst_id      = d.inst_id
ORDER BY
    d.inst_id, g.name, d.name;
