/* =============================================================================
   PURPOSE  : Objects whose DDL changed in the last N days - the "what changed?"
              query when something broke and nobody admits to a deployment.
   VIEWS    : dba_objects
   LICENSE  : None
   RAC      : N/A - dictionary view, identical from any instance.
   PARAMS   : &days_back - window, e.g. 7
   NOTES    : last_ddl_time moves for dependency recompiles too, not just real
              DDL, so a wave of PL/SQL objects with the same timestamp usually
              means one underlying change cascaded. created vs last_ddl_time
              tells you new object versus altered object.
   ============================================================================= */

col owner for a18
col object_name for a32
col object_type for a18

SELECT
    owner,
    object_name,
    object_type,
    created,
    last_ddl_time,
    status,
    CASE WHEN created > SYSDATE - &days_back THEN 'NEW' ELSE 'ALTERED' END AS change_type
FROM
    dba_objects
WHERE
    last_ddl_time > SYSDATE - &days_back
AND owner NOT IN ('SYS','SYSTEM','XDB','OUTLN','DBSNMP','AUDSYS','WMSYS',
                  'ORDSYS','MDSYS','CTXSYS','APPQOSSYS','OJVMSYS','GSMADMIN_INTERNAL')
ORDER BY
    last_ddl_time DESC;
