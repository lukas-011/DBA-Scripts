/* =============================================================================
   PURPOSE  : One line - what question this script answers.
   VIEWS    : the views it reads, comma separated
   LICENSE  : None  |  Diagnostics Pack REQUIRED (dba_hist_*)  |  other pack
   RAC      : pick ONE canonical tag, then explain why:
              GV$ REQUIRED - state is per-instance; v$ would report one node
                             as if it were the cluster
              V$ CORRECT   - controlfile-wide view; gv$ would return each row
                             once per instance
              PER-INSTANCE - reachable via gv$, but never sum across nodes
                             because the resource is per-host memory
              N/A          - dictionary or AWR view, identical from any
                             instance; gv$ does not apply
              MIXED        - deliberately uses both; say which and why
   PARAMS   : &name - what it means and an example value
   NOTES    : Caveats worth knowing before trusting the output. Sampling
              limitations, licensing traps, what a NULL means, which script to
              run next.
   ============================================================================= */

col username for a20
col machine for a30

SELECT
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.machine,
    s.status
FROM
    gv$session s
WHERE
    s.type = 'USER'
AND s.username IS NOT NULL
ORDER BY
    s.inst_id, s.sid;
