/* =============================================================================
   PURPOSE  : Session counts per database user, checked against the SESSIONS_PER_USER
              limit on each user's profile so you can see who is near the cap.
   VIEWS    : gv$session, dba_users, dba_profiles
   LICENSE  : None
   RAC      : Yes (gv$ - all instances)
   PARAMS   : None
   NOTES    : SESSIONS_PER_USER is enforced per instance, not cluster-wide, so
              compare the limit against max_on_one_instance rather than the
              total. A limit of UNLIMITED shows as NULL in pct_of_limit.
   ============================================================================= */

col username for a25
col profile for a20
col sessions_per_user_limit for a12

SELECT
    per_inst.username,
    u.profile,
    p.limit                                  AS sessions_per_user_limit,
    SUM(per_inst.cnt)                        AS total_sessions,
    SUM(per_inst.active_cnt)                 AS active_sessions,
    MAX(per_inst.cnt)                        AS max_on_one_instance,
    CASE
      WHEN p.limit IN ('UNLIMITED','DEFAULT') THEN NULL
      ELSE ROUND(MAX(per_inst.cnt) / TO_NUMBER(p.limit) * 100, 1)
    END                                      AS pct_of_limit
FROM
    (SELECT
         s.username,
         s.inst_id,
         COUNT(*)                                              AS cnt,
         SUM(CASE WHEN s.status = 'ACTIVE' THEN 1 ELSE 0 END)  AS active_cnt
     FROM  gv$session s
     WHERE s.type = 'USER'
     AND   s.username IS NOT NULL
     GROUP BY s.username, s.inst_id) per_inst
JOIN
    dba_users u    ON u.username = per_inst.username
LEFT JOIN
    dba_profiles p ON p.profile       = u.profile
                  AND p.resource_name = 'SESSIONS_PER_USER'
GROUP BY
    per_inst.username,
    u.profile,
    p.limit
ORDER BY
    total_sessions DESC;
