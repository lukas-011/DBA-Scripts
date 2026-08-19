/* =============================================================================
   PURPOSE  : Object grants held on a table - who has been granted what, and
              whether they can pass it on.
   VIEWS    : dba_tab_privs
   LICENSE  : None
   RAC      : N/A (dictionary view)
   PARAMS   : &table_name - table to inspect (case-insensitive)
   NOTES    : Direct object grants only. Access via roles, ANY-privileges, or
              ownership will not show up here.
   ============================================================================= */

col owner for a15
col table_name for a25
col grantee for a20
col privilege for a15

SELECT
    owner,
    table_name,
    grantee,
    privilege,
    grantable
FROM
    dba_tab_privs
WHERE
    table_name = UPPER('&table_name')
ORDER BY
    grantee, privilege;