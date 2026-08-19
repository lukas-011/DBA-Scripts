/* =============================================================================
   PURPOSE  : Sequences configured in ways that cause cluster-wide contention.
              One of the highest-value RAC-specific checks there is, and one of
              the least known.
   VIEWS    : dba_sequences, gv$system_event
   LICENSE  : None
   RAC      : N/A for the dictionary query, but the PROBLEM is RAC-specific -
              on a single instance these settings are nearly harmless; on RAC
              they serialise every nextval across the interconnect.
   PARAMS   : &min_cache - flag sequences cached below this, e.g. 1000
   NOTES    : Two settings hurt on RAC:
                ORDER      - forces every instance to agree on sequence order,
                             which means a cluster-wide lock on every nextval.
                NOCACHE or - forces a dictionary update per value, showing up
                small CACHE   as 'row cache lock' and 'DFS lock handle' waits.
              Default CACHE is only 20, so an application sequence left at the
              default is already a problem at RAC scale. 1000+ is normal for a
              busy sequence.
              Fix (gaps in sequence values are the accepted trade-off, and are
              harmless for surrogate keys):
                ALTER SEQUENCE <owner>.<name> CACHE 1000 NOORDER;
              Confirm the symptom in query 2 before changing anything.
   ============================================================================= */

col sequence_owner for a22
col sequence_name for a32
col issue for a34
col event for a34

/* -----------------------------------------------------------------------
   QUERY 1: Sequences likely to contend on RAC
   ----------------------------------------------------------------------- */
SELECT
    sequence_owner,
    sequence_name,
    cache_size,
    order_flag,
    last_number,
    CASE
      WHEN order_flag = 'Y' AND cache_size = 0 THEN 'ORDER + NOCACHE - worst case'
      WHEN order_flag = 'Y'                    THEN 'ORDER - cluster-wide lock'
      WHEN cache_size = 0                      THEN 'NOCACHE - dictionary update/value'
      ELSE 'cache below &min_cache'
    END AS issue
FROM
    dba_sequences
WHERE
    sequence_owner NOT IN ('SYS','SYSTEM','XDB','OUTLN','DBSNMP','AUDSYS','WMSYS',
                           'ORDSYS','MDSYS','CTXSYS','APPQOSSYS','LBACSYS','GSMADMIN_INTERNAL')
AND (cache_size < &min_cache OR order_flag = 'Y')
ORDER BY
    order_flag DESC, cache_size, sequence_owner, sequence_name;


/* -----------------------------------------------------------------------
   QUERY 2: The waits this actually causes - confirm before changing anything
   ----------------------------------------------------------------------- */
SELECT
    inst_id,
    event,
    total_waits,
    ROUND(time_waited_micro/1e6, 1)                              AS total_wait_sec,
    ROUND(time_waited_micro/1e6/NULLIF(total_waits,0)*1000, 2)   AS avg_wait_ms
FROM
    gv$system_event
WHERE
    event IN ('row cache lock','DFS lock handle','enq: SQ - contention',
              'enq: SV -  contention')
AND total_waits > 0
ORDER BY
    inst_id, time_waited_micro DESC;
