# This is the main script 
export DATE=$(date +%Y%m%d%H%M%S%N)

sqlplus -s /NOLOG <<! &
connect oracle/Welcome#1Welcome#1@kapdb

--alter system flush buffer_cache;

@mystat.sql

select /*+ parallel NO_RESULT_CACHE */ /* sql */ count(*), sum(a.object_id), min(a.object_id), max(a.object_id), avg(a.object_id) 
from iosaturationtoolkit_ctas a 
where a.object_type = 'TABLE'
and a.object_name in (select object_name from iosaturationtoolkit_ctas where object_id > 1000);

@mystat.sql


exit;
!


