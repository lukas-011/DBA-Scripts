# rac

Most scripts in this repo already use `gv$`. These are for problems that
are specifically about the cluster.

Scripts to add:

- `instance-status.sql` - node and instance state (`gv$instance`)
- `service-placement.sql` - which services run where
  (`gv$active_services`)
- `interconnect-traffic.sql` - block transfer volume and latency
  (`gv$cluster_interconnects`, `gv$dlm_misc`)
- `gc-waits.sql` - global cache wait events, for diagnosing block
  pinging between nodes
- `sessions-per-instance.sql` - connection balance across nodes
