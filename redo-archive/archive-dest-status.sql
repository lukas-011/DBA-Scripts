/* =============================================================================
   PURPOSE  : Archive destination health. A destination in ERROR state means
              archiving has stopped - the database hangs once the online logs
              wrap around.
   VIEWS    : gv$archive_dest_status
   LICENSE  : None
   RAC      : Yes - gv$ is REQUIRED here. Unlike the controlfile-based redo
              views, archive destination state is per-instance: one node can
              have a failed destination while the others are fine.
   PARAMS   : None
   NOTES    : Only configured destinations are shown; the unused slots are
              filtered out. GAP_STATUS and APPLIED_SEQ# are meaningful for
              standby destinations - see dataguard/ for those.
   ============================================================================= */

col dest_name for a25
col destination for a40
col error for a45
col status for a10

SELECT
    inst_id,
    dest_id,
    dest_name,
    status,
    type,
    destination,
    archived_seq#,
    applied_seq#,
    error
FROM
    gv$archive_dest_status
WHERE
    status <> 'INACTIVE'
ORDER BY
    inst_id, dest_id;
