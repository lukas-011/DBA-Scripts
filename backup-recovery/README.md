# backup-recovery

The folder you open when someone is panicking. Backup health, archivelog
continuity, and recovery readiness.

Scripts to add:

- `rman-backup-status.sql` - recent RMAN jobs, status and duration
  (`v$rman_backup_job_details`)
- `archivelog-gaps.sql` - missing sequences that would break recovery
  (`v$archived_log`)
- `fra-usage.sql` - flash recovery area used vs reclaimable
  (`v$recovery_file_dest`, `v$flash_recovery_area_usage`)
- `restore-points.sql` - guaranteed and normal restore points
  (`v$restore_point`)
- `backup-age-by-datafile.sql` - datafiles whose last backup is stale
  (`v$backup_datafile`)
