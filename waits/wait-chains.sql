/* =============================================================================
   PURPOSE  : Full blocking chains, following every hop to the root blocker.
              Use when locking/blocking-sessions.sql shows a chain deeper than
              one level, or when the blocker is on another instance.
   VIEWS    : gv$wait_chains
   LICENSE  : None
   RAC      : Yes - and this is the reason to prefer it over gv$lock joins:
              gv$wait_chains resolves chains that cross instances, which a
              manual self-join of gv$lock does not do reliably.
   PARAMS   : None
   NOTES    : The root blocker is the row where blocker_sid IS NULL - that is
              the session to act on. num_waiters tells you how much damage it
              is doing. Populated from the hang analysis infrastructure, so it
              can lag reality by a few seconds.
   ============================================================================= */

col wait_event_text for a35
col chain_signature for a55

SELECT
    chain_id,
    LPAD(' ', LEVEL * 2 - 2) || instance || ':' || sid AS waiter,
    sid,
    sess_serial#,
    instance,
    blocker_instance,
    blocker_sid,
    in_wait_secs,
    num_waiters,
    wait_event_text,
    CASE WHEN blocker_sid IS NULL THEN '<== ROOT BLOCKER' END AS note
FROM
    gv$wait_chains
CONNECT BY PRIOR sid          = blocker_sid
       AND PRIOR sess_serial# = blocker_sess_serial#
       AND PRIOR instance     = blocker_instance
START WITH blocker_sid IS NULL
ORDER SIBLINGS BY num_waiters DESC;
