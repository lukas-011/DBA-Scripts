# config

Instance configuration and licensing posture.

Scripts to add:

- `non-default-parameters.sql` - parameters where `isdefault = 'FALSE'`
  (`v$parameter`) - the fastest way to understand an unfamiliar database
- `hidden-parameters.sql` - underscore parameters that have been set
  (`x$ksppi`, `x$ksppcv` - requires SYS)
- `feature-usage.sql` - `dba_feature_usage_statistics`, which reveals
  separately-licensed features someone switched on by accident
- `db-summary.sql` - version, options, NLS settings, instance layout
