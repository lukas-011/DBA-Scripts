/* =============================================================================
   PURPOSE  : Cluster roll-call - which instances are up, on which hosts, since
              when. Run this first when a node is suspected down.
   VIEWS    : gv$instance
   LICENSE  : None
   RAC      : GV$ REQUIRED - this is the point of the script)
   PARAMS   : None
   NOTES    : gv$ only reaches instances that are actually up, so a missing
              instance number is itself the finding. Compare the row count
              against the expected node count rather than trusting the rows
              you get back.
              Differing startup_time values are normal after a rolling
              restart; differing VERSION values are not, outside a rolling
              patch window.
   ============================================================================= */

col instance_name for a16
col host_name for a30
col version for a12
col status for a12
col database_status for a16

SELECT
    inst_id,
    instance_number,
    instance_name,
    host_name,
    version,
    startup_time,
    ROUND(SYSDATE - startup_time, 2) AS up_days,
    status,
    database_status,
    active_state,
    thread#,
    archiver,
    blocked
FROM
    gv$instance
ORDER BY
    inst_id;
