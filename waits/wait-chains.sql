/* =============================================================================
   PURPOSE  : Full blocking chains, following every hop to the root blocker.
              Use when locking/blocking-sessions.sql shows a chain deeper than
              one level, or when the blocker is on another instance.
   VIEWS    : v$wait_chains
   LICENSE  : None
   RAC      : V$ CORRECT - there is NO gv$wait_chains; this view exists only in
              the v$ form. It does not need one: the view is built by the hang
              analysis infrastructure, which is already cluster-aware, and the
              INSTANCE / BLOCKER_INSTANCE columns identify which node each
              session lives on. That is why this beats a manual gv$lock
              self-join, which does not resolve chains crossing instances.
   PARAMS   : None
   NOTES    : The root blocker is the row where blocker_sid IS NULL - that is
              the session to act on. num_waiters tells you how much damage it
              is doing. Feed instance/sid/serial# into
              maintenance/kill-session.sql.
              Populated from hang analysis, so it can lag reality by a few
              seconds and may be empty on a healthy system.
   ============================================================================= */

col wait_event_text for a35
col waiter for a22
col note for a18

SELECT
    chain_id,
    LPAD(' ', (LEVEL - 1) * 2) || instance || ':' || sid AS waiter,
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
    v$wait_chains
CONNECT BY PRIOR sid          = blocker_sid
       AND PRIOR sess_serial# = blocker_sess_serial#
       AND PRIOR instance     = blocker_instance
START WITH blocker_sid IS NULL
ORDER SIBLINGS BY num_waiters DESC;
