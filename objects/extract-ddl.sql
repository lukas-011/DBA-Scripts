/* =============================================================================
   PURPOSE  : Extract the full DDL for an object - the thing you want before
              you alter or drop anything.
   VIEWS    : dbms_metadata, dba_objects
   LICENSE  : None
   RAC      : N/A - dictionary based, identical from any instance.
   PARAMS   : &owner, &object_name - both case-insensitive
   NOTES    : Run this and keep the output BEFORE any structural change. It is
              the cheapest rollback plan there is.
              The transform settings below strip storage clauses and tablespace
              names, which is usually what you want when moving DDL between
              environments. Drop the SQLTERMINATOR call if you want raw output.
   ============================================================================= */

SET LONG 2000000
SET LONGCHUNKSIZE 2000000
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET FEEDBACK OFF

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY',        TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE',       FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE',    TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
END;
/

/* -----------------------------------------------------------------------
   The object itself, plus its dependent indexes, constraints and triggers.
   ----------------------------------------------------------------------- */
SELECT DBMS_METADATA.GET_DDL(o.object_type, o.object_name, o.owner) AS ddl
FROM   dba_objects o
WHERE  o.owner       = UPPER('&owner')
AND    o.object_name = UPPER('&object_name')
AND    o.object_type NOT IN ('INDEX PARTITION','TABLE PARTITION',
                             'INDEX SUBPARTITION','TABLE SUBPARTITION',
                             'LOB','LOB PARTITION');

SET PAGESIZE 50
SET FEEDBACK ON
