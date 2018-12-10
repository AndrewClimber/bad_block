alter database BACKUP CONTROLFILE TO TRACE;


STARTUP NOMOUNT
CREATE CONTROLFILE REUSE DATABASE "DOCS" NORESETLOGS FORCE LOGGING ARCHIVELOG
    MAXLOGFILES 5
    MAXLOGMEMBERS 3
    MAXDATAFILES 100
    MAXINSTANCES 1
    MAXLOGHISTORY 2268
LOGFILE
  GROUP 1 '/data/oradata/docs/redo01.log'  SIZE 100M,
  GROUP 2 '/data/oradata/docs/redo02.log'  SIZE 100M,
  GROUP 3 '/data/oradata/docs/redo03.log'  SIZE 100M
DATAFILE
  '/data/oradata/docs/system01.dbf',
  '/data/oradata/docs/undotbs01.dbf',
  '/data/oradata/docs/tools01.dbf',
  '/data/oradata/docs/users01.dbf',
  '/data/oradata/docs/nrepl_tab01.dbf',
  '/data/oradata/docs/nrepl_tab02.dbf',
  '/data/oradata/docs/nrepl_idx01.dbf',
  '/data/oradata/docs/nrepl_idx02.dbf',
  '/data/oradata/docs/nrepl_lob01.dbf',
  '/data/oradata/docs/nrepl_lob02.dbf',
  '/data/oradata/docs/nrepl_lob03.dbf',
  '/data/oradata/docs/nrepl_lob04.dbf',
  '/data/oradata/docs/nrepl_lob05.dbf',
  '/data/oradata/docs/system02.dbf',
  '/data/oradata/docs/users02.dbf',
  '/data/oradata/docs/contract_lob01.dbf',
  '/data/oradata/docs/contract_lob02.dbf',
  '/data/oradata/docs/contract_lob03.dbf',
  '/data/oradata/docs/contract_lob04.dbf',
  '/data/oradata/docs/contract_lob05.dbf',
  '/data/oradata/docs/contract_lob06.dbf',
  '/data/oradata/docs/contract_lob07.dbf',
  '/data/oradata/docs/contract_lob08.dbf',
  '/data/oradata/docs/contract_lob09.dbf',
  '/data/oradata/docs/contract_lob10.dbf',
  '/data/oradata/docs/contract_lob11.dbf',
  '/data/oradata/docs/contract_lob12.dbf',
  '/data/oradata/docs/contract_lob13.dbf',
  '/data/oradata/docs/contract_lob14.dbf',
  '/data/oradata/docs/contract_lob15.dbf',
  '/data/oradata/docs/contract_lob16.dbf',
  '/data/oradata/docs/contract_lob17.dbf',
  '/data/oradata/docs/contract_lob18.dbf',
  '/data/oradata/docs/contract_lob19.dbf',
  '/data/oradata/docs/contract_lob20.dbf',
  '/data/oradata/docs/contract_lob21.dbf',
  '/data/oradata/docs/contract_tab01.dbf',
  '/data/oradata/docs/contract_tab02.dbf',
  '/data/oradata/docs/contract_tab03.dbf',
  '/data/oradata/docs/contract_tab04.dbf',
  '/data/oradata/docs/contract_idx01.dbf'
CHARACTER SET CL8ISO8859P5
;

# Configure RMAN configuration record 1
VARIABLE RECNO NUMBER;
EXECUTE :RECNO := SYS.DBMS_BACKUP_RESTORE.SETCONFIG('CHANNEL','DEVICE TYPE DISK FORMAT   ''/data/bkp/docs.erp/data_%d%U.rman''');
# Configure RMAN configuration record 2
VARIABLE RECNO NUMBER;
EXECUTE :RECNO := SYS.DBMS_BACKUP_RESTORE.SETCONFIG('CONTROLFILE AUTOBACKUP','ON');
# Configure RMAN configuration record 3
VARIABLE RECNO NUMBER;
EXECUTE :RECNO := SYS.DBMS_BACKUP_RESTORE.SETCONFIG('CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE','DISK TO ''/data/bkp/docs.erp/ctl_%F''');
# Recovery is required if any of the datafiles are restored backups,
# or if the last shutdown was not normal or immediate.
RECOVER DATABASE
# All logs need archiving and a log switch is needed.
ALTER SYSTEM ARCHIVE LOG ALL;
# Database can now be opened normally.
ALTER DATABASE OPEN;
# Commands to add tempfiles to temporary tablespaces.
# Online tempfiles have complete space information.
# Other tempfiles may require adjustment.
ALTER TABLESPACE TEMP ADD TEMPFILE '/data/oradata/docs/temp02.dbf'
     SIZE 2048M REUSE AUTOEXTEND OFF;
ALTER TABLESPACE TEMP ADD TEMPFILE '/data/oradata/docs/temp01.dbf'
     SIZE 1024M REUSE AUTOEXTEND OFF;

