/* =============================================================================
   PURPOSE  : Shared pool and library cache health - free memory, reload and
              invalidation rates, and the cursor-sharing problem that most
              often causes ORA-04031.
   VIEWS    : gv$sgastat, gv$librarycache, gv$sqlarea
   LICENSE  : None
   RAC      : PER-INSTANCE - each instance has its own shared pool in its own
              host memory. Never sum across nodes.
   PARAMS   : None
   NOTES    : High reloads or invalidations in query 2 mean objects are being
              aged out and re-parsed - usually a shared pool that is too small,
              or stats gathering invalidating cursors mid-day.
              Query 3 is the important one. Many cursors with identical
              force_matching_signature but different sql_id means literals are
              being embedded instead of bind variables. That floods the shared
              pool, drives hard parsing, and eventually gives ORA-04031. The
              fix is bind variables in the application; CURSOR_SHARING=FORCE is
              a workaround with its own costs, not a cure.
   ============================================================================= */

col pool for a16
col name for a34
col namespace for a26

/* -----------------------------------------------------------------------
   QUERY 1: Largest shared pool areas, plus free memory
   ----------------------------------------------------------------------- */
SELECT * FROM (
    SELECT
        inst_id,
        pool,
        name,
        ROUND(bytes/1024/1024, 2) AS size_mb
    FROM
        gv$sgastat
    WHERE
        pool = 'shared pool'
    ORDER BY
        bytes DESC
)
WHERE ROWNUM <= 25;


/* -----------------------------------------------------------------------
   QUERY 2: Library cache reloads and invalidations
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    namespace,
    gets,
    ROUND(gethitratio * 100, 2) AS get_hit_pct,
    pins,
    ROUND(pinhitratio * 100, 2) AS pin_hit_pct,
    reloads,
    invalidations
FROM
    gv$librarycache
WHERE
    gets > 0
ORDER BY
    inst_id, reloads DESC;


/* -----------------------------------------------------------------------
   QUERY 3: Statements not using bind variables (literal SQL)
   ----------------------------------------------------------------------- */
SELECT * FROM (
    SELECT
        force_matching_signature,
        COUNT(*)                           AS distinct_cursors,
        SUM(executions)                    AS total_execs,
        ROUND(SUM(sharable_mem)/1024/1024, 2) AS shared_pool_mb,
        MIN(sql_text)                      AS example_sql
    FROM
        gv$sqlarea
    WHERE
        force_matching_signature <> 0
    GROUP BY
        force_matching_signature
    HAVING
        COUNT(*) > 20
    ORDER BY
        distinct_cursors DESC
)
WHERE ROWNUM <= 20;
