# dba-scripts

Oracle DBA query toolkit, grouped by the problem being diagnosed rather
than the object being queried — so the folder you open is the one matching
the symptom you were handed.

85 scripts. Every one carries a header block declaring what it reads, what
it costs you in licensing, and how it behaves on RAC.

## Conventions

```sql
/* =============================================================================
   PURPOSE  : One line - what question this answers.
   VIEWS    : gv$session, gv$process
   LICENSE  : None  |  Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : how this script behaves on a cluster - see below
   PARAMS   : &sql_id - target SQL_ID
   NOTES    : Caveats worth knowing before you trust the output.
   ============================================================================= */
```

Copy [_template.sql](_template.sql) when adding a script.

**LICENSE** is load-bearing. Anything reading `dba_hist_*`,
`v$active_session_history`, or `DBMS_XPLAN.DISPLAY_AWR` needs the
Diagnostics Pack, and running it on an unlicensed database is a billable
event. Find them all:

```
grep -rl "Diagnostics Pack REQUIRED" --include=*.sql .
```

Six scripts are in that category. Everything else, including
[daily-health-check.sql](health-check/daily-health-check.sql), runs on a
bare licence.

## The RAC rule

"Make it RAC friendly" does **not** mean "use `gv$` everywhere." Blanket
`gv$` introduces two distinct bugs: it duplicates rows from controlfile-wide
views, and it invites summing per-host resources into a cluster total that
describes no actual machine.

Every `RAC:` field therefore begins with one of five canonical tags, so the
whole toolkit can be audited with a single grep:

```
grep -rh '^   RAC      :' --include=*.sql . | sed 's/.*: //' | cut -d' ' -f1-2 | sort | uniq -c
```

| Tag | Meaning | Count | Example |
|---|---|---|---|
| `GV$ REQUIRED` | State is genuinely per-instance; `v$` would silently report one node's answer as the whole cluster's | 34 | [current-waits.sql](waits/current-waits.sql), [non-default-parameters.sql](config/non-default-parameters.sql) |
| `N/A` | `dba_*` or AWR view, identical from any instance; `gv$` does not apply | 29 | [invalid-objects.sql](objects/invalid-objects.sql) |
| `V$ CORRECT` | View reads the **shared controlfile**; every instance returns identical rows, so `gv$` duplicates each row once per node | 10 | [rman-backup-status.sql](backup-recovery/rman-backup-status.sql), [log-switch-frequency.sql](redo-archive/log-switch-frequency.sql) |
| `PER-INSTANCE` | `gv$` reaches every node, but totals are **never summed** across them, because the resource is per-host memory | 7 | [pga-consumers-by-user.sql](pga/pga-consumers-by-user.sql), [sga-summary.sql](sga/sga-summary.sql) |
| `MIXED` | Deliberately uses both, for the reason stated in the header | 5 | [daily-health-check.sql](health-check/daily-health-check.sql) |

Three specifics worth internalising, each of which has bitten people:

- **Joining `gv$session` to `gv$process`** requires `AND s.inst_id = p.inst_id`.
  `paddr`/`addr` are per-instance memory addresses and *do* collide across
  nodes; joining on `paddr` alone pairs a session on one node with a
  process on another.
- **Archivelog gaps are per `THREAD#`.** Each instance has its own
  independent redo sequence numbering. Comparing sequences across threads
  invents gaps that do not exist — see
  [archivelog-gaps.sql](backup-recovery/archivelog-gaps.sql).
- **`ALTER SYSTEM KILL SESSION` needs `,@inst_id`.** Without it the
  statement targets whichever node you are connected to and silently fails
  to find a session living elsewhere. Generate it with
  [kill-session.sql](maintenance/kill-session.sql).

## Where to start

| Symptom | Go to |
|---|---|
| "Everything is hung" | [locking/blocking-sessions.sql](locking/blocking-sessions.sql), then [waits/wait-chains.sql](waits/wait-chains.sql) |
| "It was slow at 2pm" | [waits/ash-recent.sql](waits/ash-recent.sql) |
| "This query got slow" | [sql-tuning/previous-plans.sql](sql-tuning/previous-plans.sql) |
| "We're out of space" | [space-growth/tablespace-headroom.sql](space-growth/tablespace-headroom.sql) |
| "Are we backed up?" | [backup-recovery/rman-backup-status.sql](backup-recovery/rman-backup-status.sql) |
| "The server is swapping" | [pga/top-pga-consumers.sql](pga/top-pga-consumers.sql), then [sga/sga-summary.sql](sga/sga-summary.sql) |
| "Snapshot too old" | [undo/undo-usage.sql](undo/undo-usage.sql) |
| "Disk group is full" | [asm/diskgroup-space.sql](asm/diskgroup-space.sql) |
| "Storage feels slow" | [io/datafile-io.sql](io/datafile-io.sql), [io/io-by-function.sql](io/io-by-function.sql) |
| Unfamiliar database | [config/db-summary.sql](config/db-summary.sql), [config/non-default-parameters.sql](config/non-default-parameters.sql) |
| Morning check | [health-check/daily-health-check.sql](health-check/daily-health-check.sql) |

## Index

### health-check/ — run this first
| Script | Purpose | License | RAC |
|---|---|---|---|
| [daily-health-check.sql](health-check/daily-health-check.sql) | 10 checks, one OK/WARN/CRITICAL verdict each | None | Mixed |
| [alert-log.sql](health-check/alert-log.sql) | Alert log errors without shelling to the server | None | gv$ req'd |
| [failed-jobs.sql](health-check/failed-jobs.sql) | Failed, broken and disabled scheduler jobs | None | N/A |

### locking/ — "everything is hung"
| Script | Purpose | License | RAC |
|---|---|---|---|
| [blocking-sessions.sql](locking/blocking-sessions.sql) | Blocker/blocked pairs — **start here** | None | gv$ req'd |
| [what-is-blocker-doing.sql](locking/what-is-blocker-doing.sql) | Full detail on one session | None | gv$ req'd |
| [object-locked.sql](locking/object-locked.sql) | Objects a session holds locks on | None | gv$ req'd |
| [transaction-info.sql](locking/transaction-info.sql) | Transaction size — check before killing | None | gv$ req'd |

### waits/ — what sessions are stuck on
| Script | Purpose | License | RAC |
|---|---|---|---|
| [current-waits.sql](waits/current-waits.sql) | Every non-idle session's current wait | None | gv$ req'd |
| [ash-recent.sql](waits/ash-recent.sql) | Last N minutes of ASH — top events and SQL | **Diag Pack** | gv$ req'd |
| [wait-chains.sql](waits/wait-chains.sql) | Full blocking chain to the root blocker, cross-node | None | gv$ req'd |
| [top-wait-events.sql](waits/top-wait-events.sql) | Cumulative waits since startup | None | gv$ req'd |
| [waits-by-class.sql](waits/waits-by-class.sql) | I/O vs concurrency vs cluster, at a glance | None | gv$ req'd |

### sql-tuning/ — statement and plan analysis
| Script | Purpose | License | RAC |
|---|---|---|---|
| [top-sql-by-elapsed-time.sql](sql-tuning/top-sql-by-elapsed-time.sql) | Heaviest SQL in the cursor cache | None | gv$ req'd |
| [awr-top-sql.sql](sql-tuning/awr-top-sql.sql) | Heaviest SQL over a historical window | **Diag Pack** | gv$ req'd |
| [previous-plans.sql](sql-tuning/previous-plans.sql) | Did the plan change, and is the new one worse | **Diag Pack** (Q1–3) | gv$ req'd |
| [get-sql-from-sqlid.sql](sql-tuning/get-sql-from-sqlid.sql) | SQL text behind a SQL_ID | None | gv$ req'd |
| [plan-baselines.sql](sql-tuning/plan-baselines.sql) | Baselines and profiles — why a plan will not change | EE / Tuning Pack | N/A |

### sga/ — instance memory
| Script | Purpose | License | RAC |
|---|---|---|---|
| [sga-summary.sql](sga/sga-summary.sql) | SGA layout and automatic resize activity | None | Per-instance |
| [buffer-cache.sql](sga/buffer-cache.sql) | Cache efficiency and whether more would help | None | Per-instance |
| [shared-pool.sql](sga/shared-pool.sql) | Library cache, plus the literal-SQL check behind ORA-04031 | None | Per-instance |
| [memory-advisors.sql](sga/memory-advisors.sql) | Oracle's own SGA/PGA/shared pool sizing advice | None | Per-instance |

### pga/ — process memory pressure
| Script | Purpose | License | RAC |
|---|---|---|---|
| [top-pga-consumers.sql](pga/top-pga-consumers.sql) | Sessions ranked by PGA in use now | None | Per-instance |
| [inactive-pga-consumers.sql](pga/inactive-pga-consumers.sql) | Idle sessions still holding memory | None | Per-instance |
| [pga-consumers-by-user.sql](pga/pga-consumers-by-user.sql) | PGA by user and SQL_ID, per node | None | Per-instance |
| [awr-pga-consumption-by-sql-id.sql](pga/awr-pga-consumption-by-sql-id.sql) | Historical peak PGA per SQL_ID | **Diag Pack** | gv$ req'd |

### sessions/ — who is connected
| Script | Purpose | License | RAC |
|---|---|---|---|
| [session-report.sql](sessions/session-report.sql) | Full inventory, spooled to a file | None | gv$ req'd |
| [sessions-by-machine.sql](sessions/sessions-by-machine.sql) | Connection counts per client host | None | gv$ req'd |
| [sessions-per-user.sql](sessions/sessions-per-user.sql) | Counts vs each profile's SESSIONS_PER_USER cap | None | gv$ req'd |

### storage/ + space-growth/ — space now, and space later
| Script | Purpose | License | RAC |
|---|---|---|---|
| [tablespace-utilization.sql](storage/tablespace-utilization.sql) | Used and free per tablespace, as allocated | None | N/A |
| [tablespace-headroom.sql](space-growth/tablespace-headroom.sql) | Real headroom incl. autoextend — **alert on this** | None | N/A |
| [tablespace-growth-trend.sql](space-growth/tablespace-growth-trend.sql) | Growth rate and estimated days until full | **Diag Pack** | N/A |
| [top-segments-by-size.sql](space-growth/top-segments-by-size.sql) | Where the space actually went | None | N/A |
| [temp-space-consumption.sql](storage/temp-space-consumption.sql) | TEMP headroom and who is burning it | None | gv$ req'd |
| [datafile-size.sql](storage/datafile-size.sql) | Generates RESIZE DDL — review before running | None | N/A |
| [recyclebin.sql](storage/recyclebin.sql) | Space held by dropped objects — quickest space win | None | N/A |

### undo/ — "snapshot too old"
| Script | Purpose | License | RAC |
|---|---|---|---|
| [undo-usage.sql](undo/undo-usage.sql) | Undo space, tuned retention, and the ORA-01555 counter | None | gv$ req'd |
| [long-running-queries.sql](undo/long-running-queries.sql) | Queries outrunning retention — at risk *before* they fail | None | gv$ req'd |

### asm/ — storage layer
| Script | Purpose | License | RAC |
|---|---|---|---|
| [diskgroup-space.sql](asm/diskgroup-space.sql) | Capacity — **negative usable_file_mb is an emergency** | None | gv$ req'd |
| [disk-balance.sql](asm/disk-balance.sql) | Failgroup layout, rebalance state, disk I/O errors | None | gv$ req'd |

### io/ — where the time goes on disk
| Script | Purpose | License | RAC |
|---|---|---|---|
| [datafile-io.sql](io/datafile-io.sql) | Per-file read/write service times | None | gv$ req'd |
| [io-by-function.sql](io/io-by-function.sql) | I/O by cause — cache, direct, RMAN, LGWR | None | gv$ req'd |

### backup-recovery/ — "are we covered?"
| Script | Purpose | License | RAC |
|---|---|---|---|
| [rman-backup-status.sql](backup-recovery/rman-backup-status.sql) | Recent RMAN jobs, duration and throughput | None | v$ correct |
| [backup-age-by-datafile.sql](backup-recovery/backup-age-by-datafile.sql) | Datafiles that dropped out of the schedule | None | v$ correct |
| [archivelog-gaps.sql](backup-recovery/archivelog-gaps.sql) | Missing sequences, per thread | None | v$ correct |
| [fra-usage.sql](backup-recovery/fra-usage.sql) | FRA capacity — watch *reclaimable*, not used | None | v$ correct |
| [restore-points.sql](backup-recovery/restore-points.sql) | Guaranteed restore points quietly filling the FRA | None | v$ correct |
| [datafiles-in-backup-mode.sql](backup-recovery/datafiles-in-backup-mode.sql) | Files stuck in BEGIN BACKUP flooding redo | None | v$ correct |

### redo-archive/ — "it got slow at 3pm"
| Script | Purpose | License | RAC |
|---|---|---|---|
| [log-switch-frequency.sql](redo-archive/log-switch-frequency.sql) | Switches/hour per thread — redo sizing evidence | None | v$ correct |
| [archive-dest-status.sql](redo-archive/archive-dest-status.sql) | Destination errors — one node can fail alone | None | gv$ req'd |
| [redo-log-config.sql](redo-archive/redo-log-config.sql) | Group/member/size layout per thread | None | v$ correct |
| [redo-generation-by-hour.sql](redo-archive/redo-generation-by-hour.sql) | Redo volume over time, per instance | **Diag Pack** | N/A |

### rac/ — cluster-specific problems
| Script | Purpose | License | RAC |
|---|---|---|---|
| [instance-status.sql](rac/instance-status.sql) | Cluster roll-call — a missing row *is* the finding | None | gv$ req'd |
| [sessions-per-instance.sql](rac/sessions-per-instance.sql) | Load balance across nodes, and by service | None | gv$ req'd |
| [service-placement.sql](rac/service-placement.sql) | Running vs defined services | None | gv$ req'd |
| [gc-waits.sql](rac/gc-waits.sql) | Global cache waits — cost of cross-node block shipping | None | gv$ req'd |
| [interconnect-config.sql](rac/interconnect-config.sql) | Interconnect networks — IS_PUBLIC must be NO | None | gv$ req'd |
| [sequence-cache.sql](rac/sequence-cache.sql) | Sequences causing cluster-wide contention | None | N/A |

### dataguard/ — standby health
| Script | Purpose | License | RAC |
|---|---|---|---|
| [apply-transport-lag.sql](dataguard/apply-transport-lag.sql) | The two lag numbers that define standby health | None | gv$ req'd |
| [standby-gap.sql](dataguard/standby-gap.sql) | Gaps, MRP state, received vs applied | None | Mixed |
| [dg-status-messages.sql](dataguard/dg-status-messages.sql) | Recent Data Guard errors | None | v$ correct |

### objects/ — post-deployment checks
| Script | Purpose | License | RAC |
|---|---|---|---|
| [invalid-objects.sql](objects/invalid-objects.sql) | Invalid objects with their first compile error | None | N/A |
| [unusable-indexes.sql](objects/unusable-indexes.sql) | Indexes silently ignored by the optimizer | None | N/A |
| [disabled-constraints.sql](objects/disabled-constraints.sql) | Disabled or NOVALIDATE constraints | None | N/A |
| [objects-changed-recently.sql](objects/objects-changed-recently.sql) | "What changed?" when nobody admits to deploying | None | N/A |
| [extract-ddl.sql](objects/extract-ddl.sql) | Full DDL — the cheapest rollback plan there is | None | N/A |
| [partition-inventory.sql](objects/partition-inventory.sql) | Partition counts and whether the newest boundary is future | **Partitioning** | N/A |

### stats/ — optimizer statistics
| Script | Purpose | License | RAC |
|---|---|---|---|
| [table-stats.sql](stats/table-stats.sql) | Table stats, including staleness | None | N/A |
| [index-stats.sql](stats/index-stats.sql) | Index row counts and key cardinality | None | N/A |
| [column-stats.sql](stats/column-stats.sql) | Per-column cardinality, density, NULLs | None | N/A |

### maintenance/ — generates DDL, changes nothing
Every script here **prints statements only**. Review before running.

| Script | Purpose | License | RAC |
|---|---|---|---|
| [kill-session.sql](maintenance/kill-session.sql) | KILL SESSION statements with the required `,@inst_id` | None | gv$ req'd |
| [stale-stats.sql](maintenance/stale-stats.sql) | Tables needing a gather, with DML volume behind it | None | N/A |
| [gather-stats.sql](maintenance/gather-stats.sql) | DBMS_STATS calls for stale tables | None | N/A |
| [rebuild-unusable-indexes.sql](maintenance/rebuild-unusable-indexes.sql) | REBUILD statements at the right partition level | None | N/A |

### config/ — instance configuration
| Script | Purpose | License | RAC |
|---|---|---|---|
| [db-summary.sql](config/db-summary.sql) | One-screen orientation for an unfamiliar database | None | Mixed |
| [non-default-parameters.sql](config/non-default-parameters.sql) | Non-defaults, **plus cross-instance drift** | None | gv$ req'd |
| [spfile-vs-memory.sql](config/spfile-vs-memory.sql) | Changes that will vanish at the next restart | None | gv$ req'd |
| [feature-usage.sql](config/feature-usage.sql) | Licensable features in use — run before an audit | None | N/A |

### jobs/ — scheduled and long-running work
| Script | Purpose | License | RAC |
|---|---|---|---|
| [long-ops.sql](jobs/long-ops.sql) | Long operations in flight, % complete and ETA | None | gv$ req'd |
| [running-jobs.sql](jobs/running-jobs.sql) | Scheduler jobs running now, with their sessions | None | gv$ req'd |
| [datapump-jobs.sql](jobs/datapump-jobs.sql) | Data Pump jobs, with orphaned ones flagged | None | Mixed |

### security/ — access and privileges
| Script | Purpose | License | RAC |
|---|---|---|---|
| [privileged-users.sql](security/privileged-users.sql) | Who holds DBA roles, ANY-privileges, SYSDBA | None | v$ correct |
| [user-privileges.sql](security/user-privileges.sql) | Everything one user can do, following nested roles | None | N/A |
| [expiring-passwords.sql](security/expiring-passwords.sql) | Accounts about to expire or already locked | None | N/A |
| [failed-logins.sql](security/failed-logins.sql) | Locked-out accounts and failed logon attempts | None | N/A |
| [privs-needed-for-table-access.sql](security/privs-needed-for-table-access.sql) | Object grants on a table | None | N/A |

## Setup

[login.sql](login.sql) is picked up automatically by SQL\*Plus when started
from this directory. It sets shared formatting, readable date formats,
`VERIFY OFF`, and a `user@instance` prompt so production is visually
distinct from dev before you run anything. Per-column `COL ... FOR ...`
formatting stays inside individual scripts.

## Verification

**All 85 scripts execute cleanly against Oracle AI Database 26ai Free
(23.26.2.0.0)** — tested in both `CDB$ROOT` and the `FREEPDB1` PDB, in a
default SQL\*Plus session with no special client settings.

```
bash tools/verify-scripts.sh
```

Eleven static checks, no database needed: parenthesis balance, trailing
commas before `FROM`, dangling booleans, undocumented substitution
variables, `VIEWS:` claims that drifted from the SQL, unrestored SQL\*Plus
state, canonical RAC tags, cross-references, and semicolons inside open
statements.

Two limits worth stating plainly:

- The test database is **single-instance**. Every `gv$` view and column is
  confirmed to exist and the queries run, but genuine multi-node behaviour —
  cross-instance joins returning rows from two nodes, per-thread archivelog
  gaps, `,@inst_id` actually reaching another node — is unproven.
- No ASM and no Data Guard, so `asm/` and `dataguard/` are confirmed to
  parse and run but return no rows here.

## Caveats

- Scripts are written against 11gR2+ and assume Enterprise Edition where
  noted. `ONLINE` index rebuilds in
  [rebuild-unusable-indexes.sql](maintenance/rebuild-unusable-indexes.sql)
  need EE; drop the keyword on Standard.
- `v$recovery_area_usage` is named `v$flash_recovery_area_usage` on older
  releases.
- The projection in
  [tablespace-growth-trend.sql](space-growth/tablespace-growth-trend.sql)
  is a naive linear fit — a triage signal, not a capacity plan.
- `gv$asm_*` returns full detail only from an ASM instance; from a database
  instance the views are populated but sparser.
- [io-by-function.sql](io/io-by-function.sql) needs 11g or later.
- [failed-logins.sql](security/failed-logins.sql) contains both a 12c+
  unified-auditing query and an 11g traditional-auditing one. Run the one
  matching your release; the other raises ORA-00942 by design.
- `gv$wait_chains` and `gv$diag_alert_ext` **do not exist** — those two are
  `v$`-only views. `v$wait_chains` needs no `gv$` form: it carries
  `INSTANCE` and `BLOCKER_INSTANCE` and already resolves chains across
  nodes. `v$diag_alert_ext` reads the local ADR, so on RAC run it per node.
- The job columns (`owner`, `job_name`, `elapsed_time`, `running_instance`)
  live in `dba_scheduler_running_jobs`, **not** in
  `gv$scheduler_running_jobs`, which exposes only `inst_id`, `session_id`,
  `session_serial_num`, `job_id`, `paddr`, `os_process_id` and
  `session_stat_cpu`.
- Scripts were written against 11gR2+ but are only execution-verified on
  23ai/26ai. Review before running in production, particularly the
  `maintenance/` generators.
