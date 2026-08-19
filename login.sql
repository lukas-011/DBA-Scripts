-- =============================================================================
-- SQL*Plus session defaults. Run automatically when sqlplus is started from
-- this directory, so scripts here do not have to repeat these settings.
-- Per-column COL ... FOR ... formatting stays in the individual scripts.
-- =============================================================================

SET LINESIZE 200
SET PAGESIZE 50
SET TRIMSPOOL ON
SET TRIMOUT ON
SET TAB OFF
SET NULL "(null)"

-- VERIFY OFF suppresses the "old 5: ... new 5: ..." echo on substitution
-- variables, which is noise on the &owner/&table_name style scripts here.
SET VERIFY OFF

-- Long enough to show sql_text and DBMS_XPLAN output without truncating.
SET LONG 100000
SET LONGCHUNKSIZE 100000

-- Readable timestamps everywhere, including logon_time and AWR snap times.
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

-- Show the connected user and instance in the prompt, so you can tell prod
-- from dev at a glance before running anything.
SET SQLPROMPT "_USER'@'_CONNECT_IDENTIFIER> "
