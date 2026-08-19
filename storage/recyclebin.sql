/* =============================================================================
   PURPOSE  : Space held by dropped objects sitting in the recycle bin. Often
              the quickest space win available, and frequently overlooked when
              a tablespace fills up.
   VIEWS    : dba_recyclebin
   LICENSE  : None
   RAC      : N/A - dictionary view, identical from any instance.
   PARAMS   : None
   NOTES    : dba_recyclebin.space is measured in BLOCKS, and the MB figures
              here assume an 8K block size - hence "approx". On a tablespace
              with a different block size, scale accordingly.
              Recycle bin objects still occupy their original tablespace.
              Oracle reclaims them automatically under space pressure, so a
              full recycle bin is not itself a fault - but if you need space
              NOW, this is the cheapest place to get it.
              Purge one object:      PURGE TABLE <original_name>;
              Purge one tablespace:  PURGE TABLESPACE <ts> USER <user>;
              Purge everything:      PURGE DBA_RECYCLEBIN;
              Purging is IRREVERSIBLE - it removes the ability to FLASHBACK
              TABLE ... TO BEFORE DROP. Check droptime before purging anything
              dropped recently; someone may still need it back.
   ============================================================================= */

col owner for a18
col object_name for a32
col original_name for a32
col type for a18
col ts_name for a22

/* -----------------------------------------------------------------------
   QUERY 1: Space by tablespace and owner
   ----------------------------------------------------------------------- */
SELECT
    ts_name,
    owner,
    COUNT(*)                            AS objects,
    ROUND(SUM(space) * 8 / 1024, 2)     AS approx_mb
FROM
    dba_recyclebin
WHERE
    space IS NOT NULL
GROUP BY
    ts_name, owner
ORDER BY
    SUM(space) DESC;


/* -----------------------------------------------------------------------
   QUERY 2: Individual objects, largest first
   ----------------------------------------------------------------------- */
SELECT * FROM (
    SELECT
        owner,
        original_name,
        object_name,
        type,
        ts_name,
        droptime,
        can_undrop,
        ROUND(space * 8 / 1024, 2) AS approx_mb
    FROM
        dba_recyclebin
    ORDER BY
        space DESC NULLS LAST
)
WHERE ROWNUM <= 40;
