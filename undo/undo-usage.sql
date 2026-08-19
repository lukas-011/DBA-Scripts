/* =============================================================================
   PURPOSE  : Undo tablespace consumption and retention headroom - the data
              behind ORA-01555 "snapshot too old" and ORA-30036 "unable to
              extend undo".
   VIEWS    : gv$undostat, dba_undo_extents, gv$parameter
   LICENSE  : None
   RAC      : GV$ REQUIRED - each instance has its OWN undo tablespace and its
              own retention tuning. A node-specific ORA-01555 is normal and
              querying a single instance will miss it.
   PARAMS   : &hours_back - window for query 2, e.g. 24
   NOTES    : In query 1, EXPIRED space is reusable, UNEXPIRED is still within
              the retention window, ACTIVE belongs to open transactions. A
              tablespace that is mostly ACTIVE has a long-running transaction
              holding it - find it with locking/transaction-info.sql.
              In query 2: ssolderrcnt is the ORA-01555 count and nospaceerrcnt
              is the out-of-space count, per 10-minute interval. Any non-zero
              value is a real incident that already happened.
              tuned_undoretention is what Oracle actually enforced, which can
              be far below the UNDO_RETENTION parameter when space is tight
              unless the undo tablespace is set to RETENTION GUARANTEE.
   ============================================================================= */

col tablespace_name for a24
col status for a12

/* -----------------------------------------------------------------------
   QUERY 1: Undo space by status
   ----------------------------------------------------------------------- */
SELECT
    tablespace_name,
    status,
    COUNT(*)                          AS extents,
    ROUND(SUM(bytes)/1024/1024/1024, 2) AS size_gb
FROM
    dba_undo_extents
GROUP BY
    tablespace_name, status
ORDER BY
    tablespace_name, status;


/* -----------------------------------------------------------------------
   QUERY 2: Undo statistics per interval, worst first
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    begin_time,
    end_time,
    undoblks,
    txncount,
    maxquerylen                AS longest_query_sec,
    maxqueryid,
    tuned_undoretention        AS tuned_retention_sec,
    ssolderrcnt                AS ora_01555_count,
    nospaceerrcnt              AS out_of_space_count
FROM
    gv$undostat
WHERE
    begin_time > SYSDATE - (&hours_back/24)
ORDER BY
    ssolderrcnt DESC, nospaceerrcnt DESC, undoblks DESC;


/* -----------------------------------------------------------------------
   QUERY 3: Configured retention per instance
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    name,
    display_value
FROM
    gv$parameter
WHERE
    name IN ('undo_management','undo_tablespace','undo_retention')
ORDER BY
    inst_id, name;
