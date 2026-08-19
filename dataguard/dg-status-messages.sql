/* =============================================================================
   PURPOSE  : Recent Data Guard messages and errors. The first place to look
              when lag is climbing and you do not know why.
   VIEWS    : v$dataguard_status
   LICENSE  : Data Guard (included in Enterprise Edition)
   RAC      : Yes - v$ is correct; the view is fed from the local instance's
              Data Guard processes. Run it on the node reporting the problem,
              or use gv$dataguard_status to sweep all nodes at once.
   PARAMS   : &hours_back - window, e.g. 24
   NOTES    : severity 'Error' and 'Fatal' are the ones that matter; 'Warning'
              is often just a transport retry that succeeded.
   ============================================================================= */

col message for a95 word_wrapped
col severity for a12
col facility for a24

SELECT
    timestamp,
    facility,
    severity,
    dest_id,
    error_code,
    message
FROM
    v$dataguard_status
WHERE
    timestamp > SYSDATE - (&hours_back/24)
ORDER BY
    timestamp DESC;
