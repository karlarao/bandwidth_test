# This script grows the data in the iosaturationtoolkit table to over 32GB
(( n=0 ))
while (( n<15 ));do
(( n=n+1 ))
sqlplus -s /NOLOG <<! &

connect oracle/Welcome#1Welcome#1@kapdb

set timing on
set time on

@mystat.sql

alter session enable parallel dml;
insert /*+ APPEND */ into iosaturationtoolkit select * from iosaturationtoolkit;
commit;

@mystat.sql

exit;
!
wait
done
wait
