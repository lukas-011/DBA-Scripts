/* =============================================================================
   PURPOSE  : Index statistics for a table - row counts, key cardinality, and
              when stats were last gathered.
   VIEWS    : dba_ind_statistics
   LICENSE  : None
   RAC      : N/A - dictionary view, identical from any instance.
   PARAMS   : &owner, &table_name - both case-insensitive
   ============================================================================= */

SELECT
    index_name,
    num_rows,
    distinct_keys,
    last_analyzed
FROM
    dba_ind_statistics
WHERE
    owner = UPPER('&owner')
AND table_name = UPPER('&table_name');