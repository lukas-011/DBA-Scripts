/* =============================================================================
   PURPOSE  : The two numbers that define standby health: transport lag (redo
              not yet shipped) and apply lag (redo shipped but not applied).
              Run on the STANDBY.
   VIEWS    : gv$dataguard_stats
   LICENSE  : Data Guard is included in Enterprise Edition. Opening the standby
              READ ONLY while applying is Active Data Guard, which is EXTRA.
   RAC      : Yes (gv$ - REQUIRED on a RAC standby; only the apply instance
              reports meaningful apply lag, the others show it as unavailable)
   PARAMS   : None
   NOTES    : Transport lag high, apply lag low  => network or archiver problem.
              Transport lag low,  apply lag high => MRP is slow or stopped.
              Both zero on an idle primary is normal and not proof of health -
              confirm with dataguard/standby-gap.sql that MRP is actually
              running.
              datum_time is when the value was computed; a stale datum_time
              means the statistic itself is not being refreshed.
   ============================================================================= */

col name for a26
col value for a22
col unit for a30

SELECT
    inst_id,
    name,
    value,
    unit,
    time_computed,
    datum_time
FROM
    gv$dataguard_stats
ORDER BY
    inst_id, name;
