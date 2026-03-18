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