/* =============================================================================
   PURPOSE  : Failed login attempts and accounts locked by them. Detects both a
              brute-force attempt and, far more commonly, an application still
              retrying a password that was changed.
   VIEWS    : dba_users, unified_audit_trail (12c+), dba_audit_trail (11g)
   LICENSE  : None. Unified Auditing is included; Database Vault and Audit
              Vault are separate products and are NOT required here.
   RAC      : N/A - dictionary views; the audit trail is cluster-wide.
              unified_audit_trail includes an INSTANCE_ID column if you need
              to know which node a failed attempt hit.
   PARAMS   : &hours_back - window, e.g. 24
   NOTES    : Query 1 always works and needs no auditing enabled - account
              status LOCKED(TIMED) means FAILED_LOGIN_ATTEMPTS on the profile
              was exceeded. This is the fastest answer to "why can the app not
              connect".
              Queries 2 and 3 are version-specific and only return rows if
              auditing is actually enabled. Run the one matching your release;
              the other will raise ORA-00942 and that is expected.
              Unlock with: ALTER USER <name> ACCOUNT UNLOCK;
   ============================================================================= */

col username for a26
col account_status for a20
col os_username for a20
col userhost for a30
col authentication_type for a24

/* -----------------------------------------------------------------------
   QUERY 1: Accounts locked out right now (works on every version)
   ----------------------------------------------------------------------- */
SELECT
    u.username,
    u.account_status,
    u.lock_date,
    u.expiry_date,
    u.profile,
    p.limit AS failed_login_attempts_limit
FROM
    dba_users u
LEFT JOIN
    dba_profiles p
ON  p.profile       = u.profile
AND p.resource_name = 'FAILED_LOGIN_ATTEMPTS'
WHERE
    u.account_status LIKE '%LOCKED%'
ORDER BY
    u.lock_date DESC NULLS LAST;


/* -----------------------------------------------------------------------
   QUERY 2: Failed logons, 12c+ unified auditing
   ----------------------------------------------------------------------- */
SELECT
    dbusername            AS username,
    userhost,
    os_username,
    authentication_type,
    COUNT(*)              AS failed_attempts,
    MIN(event_timestamp)  AS first_attempt,
    MAX(event_timestamp)  AS last_attempt
FROM
    unified_audit_trail
WHERE
    action_name = 'LOGON'
AND return_code <> 0
AND event_timestamp > SYSTIMESTAMP - NUMTODSINTERVAL(&hours_back, 'HOUR')
GROUP BY
    dbusername, userhost, os_username, authentication_type
ORDER BY
    failed_attempts DESC;


/* -----------------------------------------------------------------------
   QUERY 3: Failed logons, 11g traditional auditing (AUDIT SESSION required)
   ----------------------------------------------------------------------- */
SELECT
    username,
    userhost,
    os_username,
    COUNT(*)          AS failed_attempts,
    MIN(timestamp)    AS first_attempt,
    MAX(timestamp)    AS last_attempt
FROM
    dba_audit_trail
WHERE
    action_name IN ('LOGON')
AND returncode <> 0
AND timestamp > SYSDATE - (&hours_back/24)
GROUP BY
    username, userhost, os_username
ORDER BY
    failed_attempts DESC;
