/* =============================================================================
   PURPOSE  : What every non-idle session is waiting on right now. The natural
              follow-up to locking/blocking-sessions.sql - that shows who is
              stuck, this shows what they are stuck on.
   VIEWS    : gv$session
   LICENSE  : None
   RAC      : GV$ REQUIRED - waits are per-instance.
   PARAMS   : None
   NOTES    : Idle wait classes are excluded, otherwise the output is drowned
              in 'SQL*Net message from client'. blocking_session is populated
              only for enqueue-style waits.
   ============================================================================= */

col username for a18
col event for a35
col wait_class for a14
col program for a25
col sql_id for a13

SELECT
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.sql_id,
    s.event,
    s.wait_class,
    s.seconds_in_wait,
    s.blocking_instance,
    s.blocking_session,
    s.program
FROM
    gv$session s
WHERE
    s.status     = 'ACTIVE'
AND s.wait_class <> 'Idle'
AND s.type       = 'USER'
ORDER BY
    s.seconds_in_wait DESC;
