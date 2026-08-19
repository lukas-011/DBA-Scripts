/* =============================================================================
   PURPOSE  : Everything one user can actually do, following roles recursively.
              Answers "how does this account have access to that table?" -
              which direct grants alone will not tell you.
   VIEWS    : dba_role_privs, dba_sys_privs, dba_tab_privs
   LICENSE  : None
   RAC      : N/A - dictionary views, identical from any instance.
   PARAMS   : &username - account to inspect (case-insensitive)
   NOTES    : The CONNECT BY walks nested roles, so a privilege granted to a
              role granted to a role granted to the user still shows up. The
              via_role column tells you where each privilege actually comes
              from - that is the one you revoke.
              Does NOT cover privileges from PUBLIC. Check those separately
              with grantee = 'PUBLIC' if an access path is still unexplained.
   ============================================================================= */

col grantee for a26
col privilege for a34
col owner for a18
col object_name for a30
col via_role for a26

/* -----------------------------------------------------------------------
   QUERY 1: Roles held, directly or nested
   ----------------------------------------------------------------------- */
SELECT DISTINCT
    granted_role,
    LEVEL AS depth
FROM
    dba_role_privs
START WITH grantee = UPPER('&username')
CONNECT BY PRIOR granted_role = grantee
ORDER BY depth, granted_role;


/* -----------------------------------------------------------------------
   QUERY 2: System privileges, direct or via any role
   ----------------------------------------------------------------------- */
SELECT
    sp.privilege,
    sp.grantee AS via_role,
    sp.admin_option
FROM
    dba_sys_privs sp
WHERE
    sp.grantee = UPPER('&username')
OR  sp.grantee IN (SELECT granted_role
                   FROM   dba_role_privs
                   START WITH grantee = UPPER('&username')
                   CONNECT BY PRIOR granted_role = grantee)
ORDER BY
    sp.privilege;


/* -----------------------------------------------------------------------
   QUERY 3: Object privileges, direct or via any role
   ----------------------------------------------------------------------- */
SELECT
    tp.owner,
    tp.table_name AS object_name,
    tp.privilege,
    tp.grantee    AS via_role,
    tp.grantable
FROM
    dba_tab_privs tp
WHERE
    tp.grantee = UPPER('&username')
OR  tp.grantee IN (SELECT granted_role
                   FROM   dba_role_privs
                   START WITH grantee = UPPER('&username')
                   CONNECT BY PRIOR granted_role = grantee)
ORDER BY
    tp.owner, tp.table_name, tp.privilege;
