/* =============================================================================
   PURPOSE  : GENERATE the correct ALTER SYSTEM KILL SESSION statements for
              sessions matching a filter. Prints DDL only - nothing is killed
              until you run the generated statements.
   VIEWS    : gv$session, v$instance, v$mystat (the latter two only to exclude
              your own session from the generated statements)
   LICENSE  : None
   RAC      : GV$ REQUIRED - and the reason to generate rather than hand-type.
              The RAC form needs the instance:
                ALTER SYSTEM KILL SESSION 'sid,serial#,@inst_id' IMMEDIATE;
              Omitting @inst_id targets the instance you are connected to and
              silently fails to find a session that lives on another node.
   PARAMS   : &username - target user, or % for all
              &idle_minutes - only sessions idle longer than this (0 for all)
   NOTES    : REVIEW THE OUTPUT BEFORE RUNNING IT. Check
              locking/transaction-info.sql first - killing a session with a
              large open transaction starts a rollback that can take longer
              than the work it is undoing, and cannot be interrupted.
              IMMEDIATE rolls back and releases locks without waiting.
              For a gentler option that waits for the current transaction:
                ALTER SYSTEM DISCONNECT SESSION 'sid,serial#,@inst_id'
                  POST_TRANSACTION;
   ============================================================================= */

SET PAGESIZE 0
SET FEEDBACK OFF
col kill_stmt for a80

SELECT
    'ALTER SYSTEM KILL SESSION ''' || s.sid || ',' || s.serial# ||
    ',@' || s.inst_id || ''' IMMEDIATE;   -- ' ||
    s.username || ' ' || s.status ||
    ' idle=' || ROUND(s.last_call_et/60) || 'm' ||
    ' machine=' || s.machine            AS kill_stmt
FROM
    gv$session s
WHERE
    s.type = 'USER'
AND s.username IS NOT NULL
AND s.username LIKE UPPER('&username')
AND s.last_call_et >= &idle_minutes * 60
   /* never generate a statement that kills the session running this script */
AND NOT (s.sid     = (SELECT sid FROM v$mystat WHERE ROWNUM = 1)
     AND s.inst_id = (SELECT instance_number FROM v$instance))
ORDER BY
    s.inst_id, s.last_call_et DESC;

SET PAGESIZE 50
SET FEEDBACK ON
