/* =============================================================================
   PURPOSE  : Full detail on one session - current wait event, SQL_ID, and how
              long it has been on the current call.
   VIEWS    : gv$session
   LICENSE  : None
   RAC      : GV$ REQUIRED - session and process state is per-instance.
   PARAMS   : &sid - session to inspect
   NOTES    : For an INACTIVE session, last_call_et is idle time, not run time.
   ============================================================================= */

col inst_id for 99
col sid for 9999
col serial# for 99999
col username for a12
col machine for a20
col program for a30
col status for a10
col sql_id for a13
col event for a30
col wait_class for a15
col minutes_running for 999.99

SELECT
    inst_id,
    sid,
    serial#,
    username,
    machine,
    program,
    status,
    sql_id,
    event,
    seconds_in_wait,
    wait_class,
    ROUND(last_call_et/60,2) AS minutes_running
FROM
    gv$session
WHERE
    sid = &sid
ORDER BY
    inst_id, sid;