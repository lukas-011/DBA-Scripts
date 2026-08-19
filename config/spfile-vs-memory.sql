/* =============================================================================
   PURPOSE  : Parameters whose running value differs from the spfile value -
              i.e. changes that will silently revert at the next restart, or
              spfile edits not yet in effect.
   VIEWS    : gv$parameter, gv$spparameter
   LICENSE  : None
   RAC      : GV$ REQUIRED - sid-qualified spfile entries are per-instance)
   PARAMS   : None
   NOTES    : This is the check that catches "we fixed it last month" changes
              made with SCOPE=MEMORY that vanished at the next bounce. Run it
              before and after any planned restart.
   ============================================================================= */

col name for a42
col running_value for a35
col spfile_value for a35

SELECT
    p.inst_id,
    p.name,
    p.display_value          AS running_value,
    sp.value                 AS spfile_value,
    p.ismodified
FROM
    gv$parameter p
LEFT JOIN
    gv$spparameter sp
ON  sp.name    = p.name
AND sp.inst_id = p.inst_id
WHERE
    sp.isspecified = 'TRUE'
AND NVL(p.display_value, '~NULL~') <> NVL(sp.value, '~NULL~')
ORDER BY
    p.name, p.inst_id;
