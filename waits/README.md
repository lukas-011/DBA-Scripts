# waits

Complements `pga/` and `locking/`: those show *who* is stuck, these show
*what they are waiting on*.

Scripts to add:

- `top-wait-events.sql` - current waits ranked by session count
  (`gv$session_event`, `gv$system_event`)
- `ash-last-n-minutes.sql` - active session history for a recent window
  (`gv$active_session_history`) - Diagnostics Pack
- `wait-chains.sql` - full blocking chain, not just one hop
  (`gv$wait_chains`)
- `waits-by-class.sql` - time grouped by wait class to separate I/O from
  concurrency from CPU (`gv$system_wait_class`)
