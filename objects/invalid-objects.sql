/* =============================================================================
   PURPOSE  : Invalid objects with their first compile error. The standard
              post-deployment check.
   VIEWS    : dba_objects, dba_errors
   LICENSE  : None
   RAC      : N/A - dictionary view, identical from any instance. gv$ does not
              apply and would be wrong here.
   PARAMS   : &owner - schema to check, or % for all
   NOTES    : Recompile everything with:
                EXEC UTL_RECOMP.RECOMP_PARALLEL(4, '<SCHEMA>');
              or $ORACLE_HOME/rdbms/admin/utlrp.sql for the whole database.
              Objects invalid only because a dependency is invalid will fix
              themselves on recompile - chase the root error first.
   ============================================================================= */

col owner for a18
col object_name for a30
col object_type for a18
col error_text for a55 word_wrapped

SELECT
    o.owner,
    o.object_name,
    o.object_type,
    o.last_ddl_time,
    e.line,
    e.text        AS error_text
FROM
    dba_objects o
LEFT JOIN
    (SELECT owner, name, type, line, text,
            ROW_NUMBER() OVER (PARTITION BY owner, name, type
                               ORDER BY sequence) AS rn
     FROM   dba_errors
     WHERE  attribute = 'ERROR') e
ON  e.owner = o.owner
AND e.name  = o.object_name
AND e.type  = o.object_type
AND e.rn    = 1
WHERE
    o.status = 'INVALID'
AND o.owner LIKE UPPER('&owner')
ORDER BY
    o.owner, o.object_type, o.object_name;
