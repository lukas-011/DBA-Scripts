# objects

Object-level health, the usual post-deployment checks.

Scripts to add:

- `invalid-objects.sql` - invalid packages/views/triggers with owner
  (`dba_objects`)
- `unusable-indexes.sql` - indexes and partitions left unusable after a
  direct-path load or partition maintenance (`dba_indexes`,
  `dba_ind_partitions`)
- `disabled-constraints.sql` - constraints disabled or not validated
  (`dba_constraints`)
- `extract-ddl.sql` - `dbms_metadata.get_ddl` wrapper
- `objects-changed-recently.sql` - by `last_ddl_time`, for "what changed?"
