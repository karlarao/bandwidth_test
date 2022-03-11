# This is the main script 
export DATE=$(date +%Y%m%d%H%M%S%N)

sqlplus -s /NOLOG <<! &
connect oracle/Welcome#1Welcome#1@kapdb

truncate table iosaturationtoolkit_ctas2;
drop table iosaturationtoolkit_ctas2 purge;
alter system flush buffer_cache;

set lines 500
@mystat.sql

create table iosaturationtoolkit_ctas2 as select * from iosaturationtoolkit;

@mystat.sql


exit;
!


