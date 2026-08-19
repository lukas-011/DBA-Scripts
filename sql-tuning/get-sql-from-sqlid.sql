/* =============================================================================
   PURPOSE  : Retrieve the SQL text behind a SQL_ID.
   VIEWS    : gv$sql
   LICENSE  : None
   RAC      : Yes (gv$ - all instances)
   PARAMS   : &sql_id - target SQL_ID
   NOTES    : Returns one row per child cursor per instance, so duplicates are
              expected. sql_text truncates at 1000 chars - use sql_fulltext from
              gv$sqlarea (a CLOB) if you need the whole statement.
   ============================================================================= */

SELECT sql_text
FROM gv$sql
WHERE sql_id = '&sql_id';