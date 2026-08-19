/* =============================================================================
   PURPOSE  : Cluster interconnect configuration - which network each instance
              is using for cache fusion traffic.
   VIEWS    : gv$cluster_interconnects
   LICENSE  : None
   RAC      : GV$ REQUIRED
   PARAMS   : None
   NOTES    : The classic misconfiguration is an interconnect resolving to the
              PUBLIC network, which cripples cache fusion. IS_PUBLIC should be
              NO on every row of query 1. SOURCE tells you where the address
              came from (OCR, cluster_interconnects parameter, or OS default).
   ============================================================================= */

col name for a18
col ip_address for a22
col source for a45

SELECT
    inst_id,
    name,
    ip_address,
    is_public,
    source
FROM
    gv$cluster_interconnects
ORDER BY
    inst_id, name;
