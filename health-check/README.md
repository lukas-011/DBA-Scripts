# health-check

The "run this first" folder - broad roll-ups for triage, before you know
which specific folder you need.

Scripts to add:

- `daily-health-check.sql` - one script calling the highest-value checks:
  tablespace headroom, invalid objects, failed jobs, backup age, blocked
  sessions
- `alert-log.sql` - recent alert log entries (`v$diag_alert_ext`)
- `failed-jobs.sql` - scheduler jobs that errored recently
  (`dba_scheduler_job_run_details`)
- `db-status-summary.sql` - uptime, session counts, active waits, on one
  screen
