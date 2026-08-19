# dataguard

Only relevant if you run standbys.

Scripts to add:

- `apply-transport-lag.sql` - the two numbers that matter
  (`v$dataguard_stats`)
- `standby-gap.sql` - sequences shipped vs applied
  (`v$archive_gap`, `v$managed_standby`)
- `dg-broker-status.sql` - configuration and errors
  (`v$dataguard_status`)
- `redo-apply-rate.sql` - whether the standby can keep up under load
