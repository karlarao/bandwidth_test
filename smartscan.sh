#!/bin/bash

  sqlplus -s /nolog <<-EOF
connect oracle/Welcome#1Welcome#1@kapdb

        col instance_name new_value instname
        col start_mb new_value start_mb
        col end_mb new_value end_mb
        col start_ic new_value start_ic
        col end_ic new_value end_ic
        col start_rsc new_value start_rsc
        col end_rsc new_value end_rsc
        col start_waits new_value start_waits
        col end_waits new_value end_waits
        col start_time_waited new_value start_time_waited
        col end_time_waited new_value end_time_waited
        
        set echo off
        set heading off
        select instance_name from v\$instance;

        select a.value/1024/1024 start_mb from v\$sysstat a where name = 'cell physical IO bytes eligible for predicate offload';
        select a.value/1024/1024 start_ic from v\$sysstat a where name = 'cell physical IO interconnect bytes';
        select a.value/1024/1024 start_rsc from v\$sysstat a where name = 'cell physical IO interconnect bytes returned by smart scan';
        select total_waits start_waits, time_waited_micro start_time_waited from v\$system_event where event = 'cell smart table scan';
        

        COLUMN dur NEW_VALUE _dur NOPRINT
        SELECT 2 dur from dual;
        exec dbms_lock.sleep(seconds => &_dur);

        
        select a.value/1024/1024 end_mb from v\$sysstat a where name = 'cell physical IO bytes eligible for predicate offload';
        select a.value/1024/1024 end_ic from v\$sysstat a where name = 'cell physical IO interconnect bytes';
        select a.value/1024/1024 end_rsc from v\$sysstat a where name = 'cell physical IO interconnect bytes returned by smart scan';
        select total_waits end_waits, time_waited_micro end_time_waited from v\$system_event where event = 'cell smart table scan';

        set heading on
        set verify off
        set lines 300
        set colsep ','
        col inst         format a10
        col aas          format 99990
        col SmartScanMBs format 999990
        col IC_MBs       format 999990
        col Returned_MBs format 999990
        col avgwt        format 999990.00
        select a.*, rpad(' '|| rpad ('@',round(a.SmartScanMBs/100,0), '@'),70,' ') "AWESOME_GRAPH"
        from (select '%' x, 
                     TO_CHAR(SYSDATE,'MM/DD/YY HH24:MI:SS') tm, 
                     '&&instname' inst,
                     (round ((&&end_time_waited - nvl('&&start_time_waited',0))/1000000, 2)) /  &_dur aas,
                     round (decode ((&&end_waits - nvl('&&start_waits', 0)), 0, to_number(NULL), ((&&end_time_waited - nvl('&&start_time_waited',0))/1000) / (&&end_waits - nvl('&&start_waits',0))), 2) avgwt,
                     (&&end_rsc - &&start_rsc) / &_dur Returned_MBs,
                     (&&end_ic - &&start_ic) / &_dur   IC_MBs,
                     (&&end_mb - &&start_mb) / &_dur   SmartScanMBs
              from dual
              ) a;

EOF
echo '-----'
echo
echo



