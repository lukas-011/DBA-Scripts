/* =============================================================================
   PURPOSE  : Recent alert log entries, without shelling onto the server.
              Errors and warnings only by default.
   VIEWS    : gv$diag_alert_ext
   LICENSE  : None
   RAC      : Yes - gv$ is REQUIRED. Every instance writes its OWN alert log,
              and the interesting error is usually on exactly one node.
   PARAMS   : &hours_back - window, e.g. 24
   NOTES    : message_type: 1 UNKNOWN, 2 INCIDENT_ERROR, 3 ERROR, 4 WARNING,
              5 NOTIFICATION, 6 TRACE. The filter keeps 2/3/4.
              This view can be slow - it parses the XML alert log on disk. Keep
              the window tight.
   ============================================================================= */

col message_text for a95 word_wrapped
col type for a16

SELECT
    inst_id,
    originating_timestamp,
    CASE message_type
      WHEN 1 THEN 'UNKNOWN'
      WHEN 2 THEN 'INCIDENT_ERROR'
      WHEN 3 THEN 'ERROR'
      WHEN 4 THEN 'WARNING'
      WHEN 5 THEN 'NOTIFICATION'
      WHEN 6 THEN 'TRACE'
    END              AS type,
    message_text
FROM
    gv$diag_alert_ext
WHERE
    originating_timestamp > SYSTIMESTAMP - NUMTODSINTERVAL(&hours_back, 'HOUR')
AND message_type IN (2, 3, 4)
ORDER BY
    originating_timestamp DESC;
