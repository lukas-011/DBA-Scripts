/* =============================================================================
   PURPOSE  : Which services are running on which instances, versus how they
              were configured. A service that failed over and never moved back
              shows up as a difference between the two queries.
   VIEWS    : gv$active_services, dba_services
   LICENSE  : None
   RAC      : GV$ REQUIRED
   PARAMS   : None
   NOTES    : dba_services lists what is defined in the database; srvctl is the
              authority on preferred/available placement, which is stored in
              the OCR and NOT visible from SQL. Use
                srvctl status service -d <db>
              to confirm intended placement.
   ============================================================================= */

col name for a35
col network_name for a35

/* -----------------------------------------------------------------------
   QUERY 1: Services currently running, by instance
   ----------------------------------------------------------------------- */
SELECT
    s.name,
    s.network_name,
    s.inst_id,
    s.creation_date
FROM
    gv$active_services s
ORDER BY
    s.name, s.inst_id;


/* -----------------------------------------------------------------------
   QUERY 2: Services defined in the database but NOT currently running
   ----------------------------------------------------------------------- */
SELECT
    d.name,
    d.network_name,
    d.failover_method,
    d.failover_type,
    d.goal
FROM
    dba_services d
WHERE
    d.name NOT IN (SELECT a.name FROM gv$active_services a)
ORDER BY
    d.name;
