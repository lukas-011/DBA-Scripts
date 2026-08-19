# space-growth

`storage/` answers "how full is it now." This folder answers "when do I
need to act."

Scripts to add:

- `top-segments-by-size.sql` - the biggest objects (`dba_segments`)
- `segment-growth-trend.sql` - growth over time from AWR
  (`dba_hist_seg_stat`, `dba_hist_tbspc_space_usage`) - Diagnostics Pack
- `tablespace-days-until-full.sql` - linear projection against maxbytes,
  which is the number worth alerting on
- `unused-space-by-segment.sql` - reclaimable space below the high-water
  mark (`dbms_space.unused_space`)
