/* =============================================================================
   PURPOSE  : Online redo log layout - groups, members, sizes and state, per
              thread. Check this before resizing anything.
   VIEWS    : v$log, v$logfile
   LICENSE  : None
   RAC      : V$ CORRECT - every instance needs its own THREAD# with its own groups.
              A thread with fewer than 2 groups, or a group with 1 member, is
              a configuration defect. v$ not gv$: both views are
              controlfile-wide and already list all threads.
   PARAMS   : None
   NOTES    : STATUS CURRENT = being written; ACTIVE = still needed for crash
              recovery; INACTIVE = safe to drop or resize. You can only
              drop/resize a group that is INACTIVE and already archived.
   ============================================================================= */

col member for a60
col status for a10

SELECT
    l.thread#,
    l.group#,
    lf.member,
    ROUND(l.bytes/1024/1024)   AS size_mb,
    l.members,
    l.archived,
    l.status,
    l.sequence#,
    l.first_time
FROM
    v$log l
JOIN
    v$logfile lf ON lf.group# = l.group#
ORDER BY
    l.thread#, l.group#, lf.member;
