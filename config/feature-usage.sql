/* =============================================================================
   PURPOSE  : Separately-licensed features the database has actually used.
              Run this BEFORE an Oracle licence audit, not after.
   VIEWS    : dba_feature_usage_statistics
   LICENSE  : None to run - but it reports on features that DO cost money
   RAC      : N/A - dictionary view, database-wide.
   PARAMS   : None
   NOTES    : Sampled weekly by the MMON background process, so a feature used
              once between samples may not appear. detected_usages > 0 with a
              recent last_usage_date is what an auditor will ask about.
              Common accidental costs: Partitioning, Advanced Compression,
              Diagnostics/Tuning Pack (any AWR or ADDM access), Spatial,
              In-Memory, Active Data Guard.
   ============================================================================= */

col name for a55
col version for a12

SELECT
    name,
    version,
    detected_usages,
    currently_used,
    first_usage_date,
    last_usage_date,
    last_sample_date
FROM
    dba_feature_usage_statistics
WHERE
    detected_usages > 0
ORDER BY
    currently_used DESC, last_usage_date DESC NULLS LAST, name;
