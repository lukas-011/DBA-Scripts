/* =============================================================================
   PURPOSE  : Accounts whose password is expiring, already expired, or locked.
              Catches the application account that is about to take the app
              down at 3am on a Sunday.
   VIEWS    : dba_users, dba_profiles
   LICENSE  : None
   RAC      : N/A - dictionary views, identical from any instance.
   PARAMS   : &days_ahead - look this far forward, e.g. 30
   NOTES    : EXPIRY_DATE is NULL when the profile sets PASSWORD_LIFE_TIME
              UNLIMITED - those rows are the safe ones and are excluded.
              Status EXPIRED(GRACE) means the password still works but the
              grace period has started; the account locks when it ends.
              Service accounts should generally sit on a profile with
              PASSWORD_LIFE_TIME UNLIMITED rather than being reset forever.
   ============================================================================= */

col username for a30
col profile for a24
col account_status for a20
col password_life_time for a20

SELECT
    u.username,
    u.account_status,
    u.expiry_date,
    ROUND(u.expiry_date - SYSDATE, 1)  AS days_until_expiry,
    u.lock_date,
    u.profile,
    p.limit                            AS password_life_time,
    u.last_login
FROM
    dba_users u
LEFT JOIN
    dba_profiles p
ON  p.profile       = u.profile
AND p.resource_name = 'PASSWORD_LIFE_TIME'
WHERE
    u.account_status <> 'OPEN'
OR (u.expiry_date IS NOT NULL AND u.expiry_date < SYSDATE + &days_ahead)
ORDER BY
    u.expiry_date NULLS LAST;
