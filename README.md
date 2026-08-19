# dba-scripts

Oracle DBA query toolkit. Scripts are grouped by the problem being
diagnosed rather than by the object being queried, so the folder you need
is the one matching the symptom you were handed.

## Conventions

Every script opens with a header block:

```sql
/* =============================================================================
   PURPOSE  : One line - what question this answers.
   VIEWS    : gv$session, gv$process
   LICENSE  : None  |  Diagnostics Pack REQUIRED (dba_hist_*)
   RAC      : Yes (gv$ - all instances)  |  No (v$ - current instance only)
   PARAMS   : &sql_id - target SQL_ID
   NOTES    : Caveats worth knowing before you trust the output.
   ============================================================================= */
```

Two fields are load-bearing:

- **LICENSE** - anything reading `dba_hist_*`, `v$active_session_history`,
  or `DBMS_XPLAN.DISPLAY_AWR` needs the Diagnostics Pack. Running those on
  an unlicensed database is a billable event. Find them all with:
  `grep -rl "Diagnostics Pack REQUIRED" .`
- **RAC** - `gv$` covers every instance, `v$` only the node you are
  connected to. On RAC, a `v$` script silently gives you a partial answer.

Naming: kebab-case files and folders; filenames describe the result
(`top-pga-consumers.sql`), not the action.

`login.sql` at the repo root is picked up automatically by SQL\*Plus when
started from this directory, and sets shared formatting. Per-column
`COL ... FOR ...` formatting stays inside individual scripts.

## Index

### jobs/ - scheduled and long-running work

| Script | Purpose | License | RAC |
|---|---|---|---|
| [long-ops.sql](jobs/long-ops.sql) | Long operations in flight, % complete and ETA | None | Yes |
| [running-jobs.sql](jobs/running-jobs.sql) | Scheduler jobs running now, joined to their sessions | None | Yes |

### locking/ - "everything is hung"

| Script | Purpose | License | RAC |
|---|---|---|---|
| [blocking-sessions.sql](locking/blocking-sessions.sql) | Blocker/blocked pairs — **start here** | None | Yes |
| [what-is-blocker-doing.sql](locking/what-is-blocker-doing.sql) | Full detail on one session | None | Yes |
| [object-locked.sql](locking/object-locked.sql) | Objects a session holds locks on | None | Yes |
| [transaction-info.sql](locking/transaction-info.sql) | Transaction size — check before killing | None | Yes |

### pga/ - process memory pressure

| Script | Purpose | License | RAC |
|---|---|---|---|
| [top-pga-consumers.sql](pga/top-pga-consumers.sql) | Sessions ranked by PGA in use now | None | No (v$) |
| [inactive-pga-consumers.sql](pga/inactive-pga-consumers.sql) | Idle sessions still holding memory | None | No (v$) |
| [pga-consumers-by-user.sql](pga/pga-consumers-by-user.sql) | PGA rolled up by user and SQL_ID | None | No (v$) |
| [awr-pga-consumption-by-sql-id.sql](pga/awr-pga-consumption-by-sql-id.sql) | Historical peak PGA per SQL_ID | **Diagnostics Pack** | Yes |

### sessions/ - who is connected

| Script | Purpose | License | RAC |
|---|---|---|---|
| [session-report.sql](sessions/session-report.sql) | Full inventory, spooled to a file | None | Yes |
| [sessions-by-machine.sql](sessions/sessions-by-machine.sql) | _stub — not yet written_ | — | — |
| [sessions-per-user.sql](sessions/sessions-per-user.sql) | _stub — not yet written_ | — | — |

### sql-tuning/ - statement and plan analysis

| Script | Purpose | License | RAC |
|---|---|---|---|
| [get-sql-from-sqlid.sql](sql-tuning/get-sql-from-sqlid.sql) | SQL text behind a SQL_ID | None | Yes |
| [previous-plans.sql](sql-tuning/previous-plans.sql) | Plan history — did the plan change, is it worse | **Diagnostics Pack** (Q1–3) | Yes |
| [top-sql-by-elapsed-time.sql](sql-tuning/top-sql-by-elapsed-time.sql) | _stub — not yet written_ | — | — |

### stats/ - optimizer statistics

| Script | Purpose | License | RAC |
|---|---|---|---|
| [table-stats.sql](stats/table-stats.sql) | Table stats, including staleness | None | N/A |
| [index-stats.sql](stats/index-stats.sql) | Index row counts and key cardinality | None | N/A |
| [column-stats.sql](stats/column-stats.sql) | Per-column cardinality, density, NULLs | None | N/A |

### storage/ - space on disk

| Script | Purpose | License | RAC |
|---|---|---|---|
| [tablespace-utilization.sql](storage/tablespace-utilization.sql) | Used and free per tablespace | None | N/A |
| [datafile-size.sql](storage/datafile-size.sql) | Generates RESIZE DDL — review before running | None | N/A |
| [temp-space-consumption.sql](storage/temp-space-consumption.sql) | _stub — not yet written_ | — | — |

### security/ - access and privileges

| Script | Purpose | License | RAC |
|---|---|---|---|
| [privs-needed-for-table-access.sql](security/privs-needed-for-table-access.sql) | Object grants on a table | None | N/A |

### Folders staged for future scripts

Each has a README listing the scripts worth adding and the views they use:
[backup-recovery/](backup-recovery/), [waits/](waits/),
[redo-archive/](redo-archive/), [space-growth/](space-growth/),
[objects/](objects/), [config/](config/), [rac/](rac/),
[dataguard/](dataguard/), [health-check/](health-check/).

## Known gaps

Four scripts are empty placeholders, marked `STATUS: STUB` in their
headers: `sessions-by-machine.sql`, `sessions-per-user.sql`,
`top-sql-by-elapsed-time.sql`, `temp-space-consumption.sql`.
