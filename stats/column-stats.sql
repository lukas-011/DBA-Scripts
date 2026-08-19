/* =============================================================================
   PURPOSE  : Per-column optimizer statistics - cardinality, density, and NULL
              counts. Use when the optimizer misjudges a predicate's selectivity.
   VIEWS    : dba_tab_col_statistics
   LICENSE  : None
   RAC      : N/A (dictionary view)
   PARAMS   : &owner, &table_name - both case-insensitive
   NOTES    : Does not show histograms. Join to dba_tab_histograms, or check the
              histogram column in dba_tab_col_statistics, for skew detail.
   ============================================================================= */

SELECT
    column_name,
    num_distinct,
    density,
    num_nulls,
    last_analyzed
FROM
    dba_tab_col_statistics
WHERE
    owner = UPPER('&owner')
AND table_name = UPPER('&table_name');