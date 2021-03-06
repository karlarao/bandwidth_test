----------------------------------------------------------------------------------------
--
-- File name:   mystat.sql
--
-- Purpose:     Reports delta of current sessions stats before and after a SQL
--
-- Author:      Carlos Sierra
--
-- Usage:       This scripts does not have parameters. It just needs to be executed
--              twice. First execution just before the SQL that needs to be evaluated.
--              Second execution right after.
--
-- Example:     @mystat.sql
--              <any sql>
--              @mystat.sql             
--
-- Description:
--
--              This script takes a snapshot of v$mystat every time it is executed. Then,
--              on first execution it does nothing else. On second execution it produces
--              a report with the gap between the first and second execution, and resets
--              all snapshots.
--              
--              If you want to capture session statistics for one SQL, then execute this
--              script right before and after your SQL.
--              
--  Notes:            
--              
--              This script uses the global temporary plan_table as a repository.
--
--              For a more robust tool use Tanel Poder snaper at
--              http://blog.tanelpoder.com
--
-- Contribution/s:
--              Karl Arao - added union all to v$session_event and v$sess_time_model 
--             
---------------------------------------------------------------------------------------
--
-- snap of v$mystat, v$session_event, v$sess_time_model
INSERT INTO plan_table (
       statement_id /* record_type */,
       timestamp, 
       object_node /* class */, 
       object_alias /* name */, 
       cost /* value */)
SELECT 'v$mystat' record_type,
       SYSDATE,
       'Mystat:' || ' ' || TRIM (',' FROM
       TRIM (' ' FROM
       DECODE(BITAND(n.class,   1),   1, 'User, ')||
       DECODE(BITAND(n.class,   2),   2, 'Redo, ')||
       DECODE(BITAND(n.class,   4),   4, 'Enqueue, ')||
       DECODE(BITAND(n.class,   8),   8, 'Cache, ')||
       DECODE(BITAND(n.class,  16),  16, 'OS, ')||
       DECODE(BITAND(n.class,  32),  32, 'RAC, ')||
       DECODE(BITAND(n.class,  64),  64, 'SQL, ')||
       DECODE(BITAND(n.class, 128), 128, 'Debug, ')
       )) class,
       n.name,
       s.value
  FROM v$mystat s,
       v$statname n
 WHERE s.statistic# = n.statistic#
union all
        select 
            'v$mystat' record_type,
            SYSDATE,
            'Event:' || ' ' || wait_class || ' - ' || event as class, 
            measure, 
            value
        from 
        (
        select * from v$session_event 
        unpivot (value for measure in (TOTAL_WAITS as 'TOTAL_WAITS', 
                                        TOTAL_TIMEOUTS as 'TOTAL_TIMEOUTS',
                                        TIME_WAITED as 'TIME_WAITED',
                                        AVERAGE_WAIT as 'AVERAGE_WAIT',
                                        MAX_WAIT as 'MAX_WAIT',
                                        TIME_WAITED_MICRO as 'TIME_WAITED_MICRO', 
                                        EVENT_ID as 'EVENT_ID',
                                        WAIT_CLASS_ID as 'WAIT_CLASS_ID',
                                        WAIT_CLASS# as 'WAIT_CLASS#'
                                        ))
        where sid in (select /*+ no_merge */ sid from v$mystat where rownum = 1)
        )
union all 
        select 
            'v$mystat' record_type,
            SYSDATE,
            'Time_Model' class,
            stat_name measure, 
            value
        from 
        (
        select * from v$sess_time_model
        where sid in (select /*+ no_merge */ sid from v$mystat where rownum = 1)
        );

--
DEF date_mask = 'YYYY-MM-DD HH24:MI:SS';
COL snap_date_end NEW_V snap_date_end;
COL snap_date_begin NEW_V snap_date_begin;
SET VER OFF PAGES 1000 LINES 500;
--
-- end snap
SELECT TO_CHAR(MAX(timestamp), '&&date_mask.') snap_date_end
  FROM plan_table
 WHERE statement_id = 'v$mystat';
--
-- begin snap (null if there is only one snap)
SELECT TO_CHAR(MAX(timestamp), '&&date_mask.') snap_date_begin
  FROM plan_table
 WHERE statement_id = 'v$mystat'
   AND TO_CHAR(timestamp, '&&date_mask.') < '&&snap_date_end.';
--
COL statistics_name FOR A100 HEA "Statistics Name";
COL difference FOR 999,999,999,999 HEA "Difference";
--
-- report only if there is a begin and end snaps
SELECT (e.cost - b.cost) difference,
       b.object_node||': '||b.object_alias statistics_name
       --b.object_alias statistics_name
  FROM plan_table b,
       plan_table e
 WHERE '&&snap_date_begin.' IS NOT NULL
   AND b.statement_id = 'v$mystat'
   AND b.timestamp = TO_DATE('&&snap_date_begin.', '&&date_mask.')
   AND e.statement_id = 'v$mystat'
   AND e.timestamp = TO_DATE('&&snap_date_end.', '&&date_mask.')
   AND e.object_alias = b.object_alias /* name */
   AND e.object_node = b.object_node
   AND e.cost > b.cost /* value */ 
 ORDER BY
       b.object_node,
       b.object_alias;

--
-- report snaps
SELECT '&&snap_date_begin.' snap_date_begin,
       '&&snap_date_end.' snap_date_end
  FROM DUAL
 WHERE '&&snap_date_begin.' IS NOT NULL;
--
-- delete only if report is not empty   
DELETE plan_table 
 WHERE '&&snap_date_begin.' IS NOT NULL 
   AND statement_id = 'v$mystat';
-- end

