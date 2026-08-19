/* =============================================================================
   PURPOSE  : Constraints that are disabled or not validated. These are a data
              integrity risk and they also stop the optimizer using the
              constraint for query rewrite and join elimination.
   VIEWS    : dba_constraints
   LICENSE  : None
   RAC      : N/A - dictionary view, identical from any instance.
   PARAMS   : &owner - schema to check, or % for all
   NOTES    : ENABLED NOVALIDATE is a legitimate steady state after a bulk
              load - new rows are checked, existing ones were not. DISABLED is
              almost never intentional in production.
              Constraint types: P primary, R foreign, U unique, C check.
   ============================================================================= */

col owner for a18
col constraint_name for a30
col table_name for a30
col type for a14

SELECT
    owner,
    table_name,
    constraint_name,
    CASE constraint_type
      WHEN 'P' THEN 'PRIMARY KEY'
      WHEN 'R' THEN 'FOREIGN KEY'
      WHEN 'U' THEN 'UNIQUE'
      WHEN 'C' THEN 'CHECK'
      ELSE constraint_type
    END              AS type,
    status,
    validated,
    deferrable
FROM
    dba_constraints
WHERE
    (status <> 'ENABLED' OR validated <> 'VALIDATED')
AND owner LIKE UPPER('&owner')
AND owner NOT IN ('SYS','SYSTEM','XDB','OUTLN','DBSNMP','AUDSYS')
ORDER BY
    owner, table_name, constraint_name;
