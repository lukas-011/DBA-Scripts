/* =============================================================================
   PURPOSE  : Recent alert log entries, without shelling onto the server.
   VIEWS    : v$diag_alert_ext
   LICENSE  : None
   RAC      : V$ CORRECT - there is NO gv$diag_alert_ext; this view exists only
              in the v$ form. It reads the LOCAL instance's ADR home, so on
              RAC run it on each node, or connect to the node that reported the
              problem. INSTANCE_ID exists (note: not INST_ID) but is frequently
              NULL, so do not rely on it to tell nodes apart - rely on which
              instance you connected to.
   PARAMS   : &hours_back - window, e.g. 24
   NOTES    : Filter by message_text, NOT by message_type. Verified against a
              live 23ai alert log of 1133 rows:
                - the real ORA-00800 errors were message_type 1 (UNKNOWN)
                - message_type 3 (ERROR) was mostly routine noise: "Resize
                  operation completed", and trace continuation lines at
                  message_level 32 such as "Address : 0x78311d48"
              So the intuitive filter (message_type IN (2,3,4)) both misses
              real errors and floods you with non-errors. Query 1 greps for an
              actual ORA- code instead, which is the highest-signal filter.
              message_level is more reliable than message_type: 1 CRITICAL,
              2 SEVERE, 8 IMPORTANT, 16 NORMAL. Values outside that set do
              occur (32 and 4294967295 were both present).
              This view parses the XML alert log on disk and can be slow. Keep
              the window tight.
   ============================================================================= */

col message_text for a88 word_wrapped
col ora_code for a12
col type for a16

/* -----------------------------------------------------------------------
   QUERY 1: Messages carrying an Oracle error code - start here
   ----------------------------------------------------------------------- */
SELECT
    originating_timestamp,
    REGEXP_SUBSTR(message_text, 'ORA-[0-9]+') AS ora_code,
    message_level,
    message_text
FROM
    v$diag_alert_ext
WHERE
    originating_timestamp > SYSTIMESTAMP - NUMTODSINTERVAL(&hours_back, 'HOUR')
AND REGEXP_LIKE(message_text, 'ORA-[0-9]+')
ORDER BY
    originating_timestamp DESC;


/* -----------------------------------------------------------------------
   QUERY 2: CRITICAL and SEVERE messages by level, error code or not.
   Catches things like "Checker run found 8 new persistent data failures",
   which carries no ORA- code but absolutely matters.
   ----------------------------------------------------------------------- */
SELECT
    originating_timestamp,
    message_level,
    CASE message_type
      WHEN 1 THEN 'UNKNOWN'        WHEN 2 THEN 'INCIDENT_ERROR'
      WHEN 3 THEN 'ERROR'          WHEN 4 THEN 'WARNING'
      WHEN 5 THEN 'NOTIFICATION'   WHEN 6 THEN 'TRACE'
    END              AS type,
    message_text
FROM
    v$diag_alert_ext
WHERE
    originating_timestamp > SYSTIMESTAMP - NUMTODSINTERVAL(&hours_back, 'HOUR')
AND message_level <= 2
ORDER BY
    originating_timestamp DESC;


/* -----------------------------------------------------------------------
   QUERY 3: Reference - what type/level mix this database actually produces.
   Run once to calibrate the filters above for your environment.
   ----------------------------------------------------------------------- */
SELECT
    message_type,
    message_level,
    COUNT(*)                              AS messages,
    SUM(CASE WHEN REGEXP_LIKE(message_text, 'ORA-[0-9]+')
             THEN 1 ELSE 0 END)           AS with_ora_code,
    SUBSTR(MIN(message_text), 1, 50)      AS sample
FROM
    v$diag_alert_ext
WHERE
    originating_timestamp > SYSTIMESTAMP - NUMTODSINTERVAL(&hours_back, 'HOUR')
GROUP BY
    message_type, message_level
ORDER BY
    message_type, message_level;
