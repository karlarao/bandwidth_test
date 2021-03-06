
-- CREATE JOB
BEGIN
    SYS.DBMS_SCHEDULER.CREATE_JOB (
            job_name => '"SYSTEM"."AWR_1MIN_SNAP"',
            job_type => 'PLSQL_BLOCK',
            job_action => 'BEGIN
dbms_workload_repository.create_snapshot;
END;',
            number_of_arguments => 0,
            start_date => SYSTIMESTAMP,
            repeat_interval => 'FREQ=MINUTELY;BYSECOND=0',
            end_date => NULL,
            job_class => '"SYS"."DEFAULT_JOB_CLASS"',
            enabled => FALSE,
            auto_drop => FALSE,
            comments => 'AWR_1MIN_SNAP',
            credential_name => NULL,
            destination_name => NULL);

    SYS.DBMS_SCHEDULER.SET_ATTRIBUTE( 
             name => '"SYSTEM"."AWR_1MIN_SNAP"', 
             attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_OFF);
          
    SYS.DBMS_SCHEDULER.enable(
             name => '"SYSTEM"."AWR_1MIN_SNAP"');

END; 
/


-- ENABLE JOB
BEGIN
    SYS.DBMS_SCHEDULER.enable(
             name => '"SYSTEM"."AWR_1MIN_SNAP"');
END;
/   


-- RUN JOB
BEGIN
	SYS.DBMS_SCHEDULER.run_job('"SYSTEM"."AWR_1MIN_SNAP"');
END;
/


-- MONITOR JOB
SELECT * FROM DBA_SCHEDULER_JOB_LOG WHERE job_name = 'AWR_1MIN_SNAP';

col JOB_NAME format a15
col START_DATE format a25
col LAST_START_DATE format a25
col NEXT_RUN_DATE format a25
SELECT job_name, enabled, start_date, last_start_date, next_run_date FROM DBA_SCHEDULER_JOBS WHERE job_name = 'AWR_1MIN_SNAP';


-- AWR get recent snapshot
select * from 
(SELECT s0.instance_number, s0.snap_id, s0.startup_time,
  TO_CHAR(s0.END_INTERVAL_TIME,'YYYY-Mon-DD HH24:MI:SS') snap_start,
  TO_CHAR(s1.END_INTERVAL_TIME,'YYYY-Mon-DD HH24:MI:SS') snap_end,
  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) ela_min
FROM dba_hist_snapshot s0,
  dba_hist_snapshot s1
WHERE s1.snap_id           = s0.snap_id + 1
ORDER BY snap_id DESC)
where rownum < 11;

