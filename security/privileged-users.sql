/* =============================================================================
   PURPOSE  : Who holds administrative power in this database - DBA-style
              roles, dangerous system privileges, and SYSDBA/SYSOPER.
              The standard access review query.
   VIEWS    : dba_role_privs, dba_sys_privs, v$pwfile_users
   LICENSE  : None
   RAC      : Yes - v$pwfile_users is correct as v$; the password file is
              per-node, so an account can be SYSDBA on one node only if the
              password files have drifted. Compare across nodes if that is a
              concern.
   PARAMS   : None
   NOTES    : ANY-privileges are the ones auditors care about most: SELECT ANY
              TABLE bypasses every object grant you carefully set up. ADMIN
              option means the grantee can pass the privilege on.
   ============================================================================= */

col grantee for a30
col privilege_or_role for a34
col source for a16

SELECT grantee, granted_role AS privilege_or_role, 'ROLE' AS source,
       admin_option, default_role
FROM   dba_role_privs
WHERE  granted_role IN ('DBA','PDB_DBA','SYSDBA','IMP_FULL_DATABASE',
                        'EXP_FULL_DATABASE','DATAPUMP_IMP_FULL_DATABASE',
                        'AUDIT_ADMIN','SELECT_CATALOG_ROLE')
AND    grantee NOT IN ('SYS','SYSTEM')
UNION ALL
SELECT grantee, privilege, 'SYS PRIVILEGE', admin_option, NULL
FROM   dba_sys_privs
WHERE  (privilege LIKE '%ANY%' OR privilege IN ('BECOME USER','ALTER SYSTEM',
                                                'ALTER DATABASE','UNLIMITED TABLESPACE',
                                                'CREATE ANY DIRECTORY','GRANT ANY OBJECT PRIVILEGE'))
AND    grantee NOT IN ('SYS','SYSTEM','DBA','IMP_FULL_DATABASE','EXP_FULL_DATABASE',
                       'DATAPUMP_IMP_FULL_DATABASE','OEM_MONITOR')
UNION ALL
SELECT username, DECODE(sysdba,'TRUE','SYSDBA','SYSOPER'), 'PASSWORD FILE', NULL, NULL
FROM   v$pwfile_users
ORDER BY 3, 1, 2;
