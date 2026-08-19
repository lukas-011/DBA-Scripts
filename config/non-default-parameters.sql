/* =============================================================================
   PURPOSE  : Every parameter explicitly set away from its default. The fastest
              way to understand an unfamiliar database.
   VIEWS    : gv$parameter
   LICENSE  : None
   RAC      : Yes - gv$ is REQUIRED and this is one of the highest-value RAC
              checks in the toolkit. Parameters CAN legitimately differ per
              instance, but an unintended difference (one node with a smaller
              SGA, a different optimizer setting, a stale value after a
              restart) produces symptoms that look random because they only
              appear on one node. Query 2 finds exactly those.
   PARAMS   : None
   NOTES    : isdefault='FALSE' means set in the spfile or altered at runtime.
              Cross-check gv$spparameter for what will survive a restart -
              an ALTER SYSTEM ... SCOPE=MEMORY change shows here but not there.
   ============================================================================= */

col name for a42
col display_value for a45

/* -----------------------------------------------------------------------
   QUERY 1: Non-default parameters, per instance
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    name,
    display_value,
    isdefault,
    ismodified,
    isbasic
FROM
    gv$parameter
WHERE
    isdefault = 'FALSE'
ORDER BY
    name, inst_id;


/* -----------------------------------------------------------------------
   QUERY 2: Parameters that DIFFER between instances - the RAC drift check
   ----------------------------------------------------------------------- */
SELECT
    name,
    COUNT(DISTINCT NVL(display_value, '~NULL~')) AS distinct_values,
    COUNT(*)                                     AS instances_reporting,
    LISTAGG(inst_id || '=' || NVL(display_value, '(null)'), '  |  ')
      WITHIN GROUP (ORDER BY inst_id)            AS values_by_instance
FROM
    gv$parameter
GROUP BY
    name
HAVING
    COUNT(DISTINCT NVL(display_value, '~NULL~')) > 1
ORDER BY
    name;
