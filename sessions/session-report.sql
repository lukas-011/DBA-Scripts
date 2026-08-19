/* =============================================================================
   PURPOSE  : Full connected-session inventory, spooled to a file. Useful as a
              point-in-time snapshot before a restart or during an incident.
   VIEWS    : gv$session
   LICENSE  : None
   RAC      : GV$ REQUIRED - session and process state is per-instance.
   PARAMS   : None
   OUTPUT   : Spools to session_report.txt in the current working directory,
              overwriting any existing file of that name.
   ============================================================================= */

SET LINESIZE 200
SET PAGESIZE 1000
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET ECHO OFF
SPOOL session_report.txt

SELECT
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.status,
    s.osuser,
    s.machine,
    s.program,
    s.module,
    s.logon_time,
    ROUND((SYSDATE - s.logon_time) * 24, 2)      AS hours_connected,
    s.last_call_et                                 AS idle_seconds,
    s.sql_id,
    s.blocking_session,
    s.wait_class,
    s.event
FROM
    gv$session s
WHERE
    s.type = 'USER'
ORDER BY
    s.inst_id,
    s.status,
    s.username;

SPOOL OFF
SET FEEDBACK ON