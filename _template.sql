/* =============================================================================
   PURPOSE  : One line - what question this script answers.
   VIEWS    : the views it reads, comma separated
   LICENSE  : None  |  Diagnostics Pack REQUIRED (dba_hist_*)  |  other pack
   RAC      : Yes (gv$ - REQUIRED, state is per-instance)
            | Yes - v$ is CORRECT here (controlfile-wide, gv$ would duplicate)
            | Per-instance BY DESIGN (host resource, never sum across nodes)
            | N/A - dictionary view, identical from any instance
   PARAMS   : &name - what it means and an example value
   NOTES    : Caveats worth knowing before trusting the output. Sampling
              limitations, licensing traps, what a NULL means, which script to
              run next.
   ============================================================================= */

col some_column for a30

SELECT
    ...
FROM
    ...
ORDER BY
    ...;
