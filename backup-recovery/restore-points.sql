/* =============================================================================
   PURPOSE  : Restore points and their storage cost. Guaranteed restore points
              never age out - a forgotten one will fill the FRA and stop the
              database.
   VIEWS    : v$restore_point
   LICENSE  : None (Flashback Database is included in Enterprise Edition)
   RAC      : Yes - v$ is CORRECT (controlfile-wide, same on every instance).
   PARAMS   : None
   NOTES    : GUARANTEE_FLASHBACK_DATABASE = YES is the dangerous kind - it
              pins every flashback log needed to get back to that SCN. Drop it
              once the change window it covered is closed:
                DROP RESTORE POINT <name>;
   ============================================================================= */

col name for a35
col guaranteed for a10

SELECT
    name,
    scn,
    time,
    guarantee_flashback_database            AS guaranteed,
    ROUND(storage_size/1024/1024/1024, 2)   AS storage_gb,
    ROUND(SYSDATE - CAST(time AS DATE), 2)  AS age_days,
    preserved
FROM
    v$restore_point
ORDER BY
    time;
