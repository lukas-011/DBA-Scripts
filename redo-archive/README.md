# redo-archive

Classic root cause for "the database got slow at 3pm."

Scripts to add:

- `log-switch-frequency.sql` - switches per hour, pivoted by day
  (`v$log_history`) - more than ~4-6/hour means redo logs are undersized
- `redo-generation-by-hour.sql` - redo volume over time
  (`dba_hist_sysstat`) - Diagnostics Pack
- `archive-dest-status.sql` - archive destination errors
  (`v$archive_dest_status`)
- `redo-log-config.sql` - group/member/size layout (`v$log`, `v$logfile`)
