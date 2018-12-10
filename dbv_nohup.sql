spool dbv_parallel.csh
set linesize 1000
set pagesize 0
select
 'nohup dbv blocksize=8192 file='||name||' logfile='||
  substr(name,instr(name,'/',-1)+1,length(name))||'.log &' "-- ksh command"
  from v$datafile;

 where 1=17  and file# >= 18  and file# < 30;
