

-- DISABLE JOB
BEGIN
    SYS.DBMS_SCHEDULER.disable(
             name => '"SYSTEM"."AWR_1MIN_SNAP"');
END;
/   


-- DROP JOB
BEGIN
    SYS.DBMS_SCHEDULER.DROP_JOB(job_name => '"SYSTEM"."AWR_1MIN_SNAP"',
                                defer => false,
                                force => true);
END;
/


col JOB_NAME format a15
col START_DATE format a25
col LAST_START_DATE format a25
col NEXT_RUN_DATE format a25
SELECT job_name, enabled, start_date, last_start_date, next_run_date FROM DBA_SCHEDULER_JOBS WHERE job_name = 'AWR_1MIN_SNAP';

