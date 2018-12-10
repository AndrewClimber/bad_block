1.
    select owner,table_name from dba_lobs
    where logging='NO'

OWNER                          TABLE_NAME
------------------------------ ------------------------------
SYSTEM                         DEF$_TEMP$LOB
SYSTEM                         DEF$_TEMP$LOB
SYSTEM                         DEF$_TEMP$LOB
SYSTEM                         LOGMNR_SPILL$
NREPL                          NREPL_ATOM
NREPL                          NREPL_ATOM
CONTRACT_MONEY                 CREATE$JAVA$LOB$TABLE
* CONTRACT_MONEY                 DOCUMENT_FILE
CONTRACT_MONEY                 TEMPLATE
ERP                            CREATE$JAVA$LOB$TABLE
* ERP                            DOCUMENT_FILE

OWNER                          TABLE_NAME
------------------------------ ------------------------------
ERP                            TEMPLATE


2.

select owner,table_name,tablespace_name from dba_tables 
where logging='NO' and temporary='N'


OWNER                          TABLE_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
SYSTEM                         DEF$_TEMP$LOB                  SYSTEM
PERFSTAT                       STATS$DATABASE_INSTANCE        USERS
PERFSTAT                       STATS$LEVEL_DESCRIPTION        USERS
PERFSTAT                       STATS$SNAPSHOT                 USERS
PERFSTAT                       STATS$DB_CACHE_ADVICE          USERS
PERFSTAT                       STATS$FILESTATXS               USERS
PERFSTAT                       STATS$TEMPSTATXS               USERS
PERFSTAT                       STATS$LATCH                    USERS
PERFSTAT                       STATS$LATCH_CHILDREN           USERS
PERFSTAT                       STATS$LATCH_PARENT             USERS
PERFSTAT                       STATS$LATCH_MISSES_SUMMARY     USERS

OWNER                          TABLE_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
PERFSTAT                       STATS$LIBRARYCACHE             USERS
PERFSTAT                       STATS$BUFFER_POOL_STATISTICS   USERS
PERFSTAT                       STATS$ROLLSTAT                 USERS
PERFSTAT                       STATS$ROWCACHE_SUMMARY         USERS
PERFSTAT                       STATS$SGA                      USERS
PERFSTAT                       STATS$SGASTAT                  USERS
PERFSTAT                       STATS$SYSSTAT                  USERS
PERFSTAT                       STATS$SESSTAT                  USERS
PERFSTAT                       STATS$SYSTEM_EVENT             USERS
PERFSTAT                       STATS$SESSION_EVENT            USERS
PERFSTAT                       STATS$BG_EVENT_SUMMARY         USERS

OWNER                          TABLE_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
PERFSTAT                       STATS$WAITSTAT                 USERS
PERFSTAT                       STATS$ENQUEUE_STAT             USERS
PERFSTAT                       STATS$SQL_SUMMARY              USERS
PERFSTAT                       STATS$SQLTEXT                  USERS
PERFSTAT                       STATS$SQL_STATISTICS           USERS
PERFSTAT                       STATS$RESOURCE_LIMIT           USERS
PERFSTAT                       STATS$DLM_MISC                 USERS
PERFSTAT                       STATS$UNDOSTAT                 USERS
PERFSTAT                       STATS$SQL_PLAN_USAGE           USERS
PERFSTAT                       STATS$SQL_PLAN                 USERS
PERFSTAT                       STATS$SEG_STAT                 USERS

OWNER                          TABLE_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
PERFSTAT                       STATS$SEG_STAT_OBJ             USERS
PERFSTAT                       STATS$PGASTAT                  USERS
PERFSTAT                       STATS$IDLE_EVENT               USERS
PERFSTAT                       STATS$PARAMETER                USERS
PERFSTAT                       STATS$INSTANCE_RECOVERY        USERS
PERFSTAT                       STATS$STATSPACK_PARAMETER      USERS
PERFSTAT                       STATS$SHARED_POOL_ADVICE       USERS
PERFSTAT                       STATS$SQL_WORKAREA_HISTOGRAM   USERS
PERFSTAT                       STATS$PGA_TARGET_ADVICE        USERS
ERP                            STAGE_SPLIT_BTYPE_TMP          CONTRACT
ERP                            TOAD_PLAN_SQL                  CONTRACT

OWNER                          TABLE_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
ERP                            PRINTER_QUEUE                  CONTRACT
ERP                            WORK_PLAN_DEPARTMENT           CONTRACT
ERP                            TOURNIQUET_EVENT_TMP           CONTRACT
ERP                            WORKPLACE_TIME_BACKUP          CONTRACT
ERP                            TMP_PHONES                     CONTRACT
ERP                            CONTRACT_MAIN_LINK             CONTRACT
SYS                            REPAIR_TEST                    USERS
SYS                            ORPHAN_TEST                    USERS
ERP                            DOCUMENT_FILE_CHECK_010210     CONTRACT
ERP                            DOCUMENT_FILE_TMP              CONTRACT

54 rows selected.

3.
select owner,index_name,tablespace_name from dba_indexes 
where logging='NO'


OWNER                          INDEX_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
PERFSTAT                       STATS$DATABASE_INSTANCE_PK     USERS
PERFSTAT                       STATS$LEVEL_DESCRIPTION_PK     USERS
PERFSTAT                       STATS$SNAPSHOT_PK              USERS
PERFSTAT                       STATS$DB_CACHE_ADVICE_PK       USERS
PERFSTAT                       STATS$FILESTATXS_PK            USERS
PERFSTAT                       STATS$TEMPSTATXS_PK            USERS
PERFSTAT                       STATS$LATCH_PK                 USERS
PERFSTAT                       STATS$LATCH_CHILDREN_PK        USERS
PERFSTAT                       STATS$LATCH_PARENT_PK          USERS
PERFSTAT                       STATS$LATCH_MISSES_SUMMARY_PK  USERS
PERFSTAT                       STATS$LIBRARYCACHE_PK          USERS

OWNER                          INDEX_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
PERFSTAT                       STATS$BUFFER_POOL_STATS_PK     USERS
PERFSTAT                       STATS$ROLLSTAT_PK              USERS
PERFSTAT                       STATS$ROWCACHE_SUMMARY_PK      USERS
PERFSTAT                       STATS$SGA_PK                   USERS
PERFSTAT                       STATS$SGASTAT_U                USERS
PERFSTAT                       STATS$SYSSTAT_PK               USERS
PERFSTAT                       STATS$SESSTAT_PK               USERS
PERFSTAT                       STATS$SYSTEM_EVENT_PK          USERS
PERFSTAT                       STATS$SESSION_EVENT_PK         USERS
PERFSTAT                       STATS$BG_EVENT_SUMMARY_PK      USERS
PERFSTAT                       STATS$WAITSTAT_PK              USERS

OWNER                          INDEX_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
PERFSTAT                       STATS$ENQUEUE_STAT_PK          USERS
PERFSTAT                       STATS$SQL_SUMMARY_PK           USERS
PERFSTAT                       STATS$SQLTEXT_PK               USERS
PERFSTAT                       STATS$SQL_STATISTICS_PK        USERS
PERFSTAT                       STATS$RESOURCE_LIMIT_PK        USERS
PERFSTAT                       STATS$DLM_MISC_PK              USERS
PERFSTAT                       STATS$UNDOSTAT_PK              USERS
PERFSTAT                       STATS$SQL_PLAN_USAGE_PK        USERS
PERFSTAT                       STATS$SQL_PLAN_USAGE_HV        USERS
PERFSTAT                       STATS$SQL_PLAN_PK              USERS
PERFSTAT                       STATS$SEG_STAT_PK              USERS

OWNER                          INDEX_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
PERFSTAT                       STATS$SEG_STAT_OBJ_PK          USERS
PERFSTAT                       STATS$SQL_PGASTAT_PK           USERS
PERFSTAT                       STATS$IDLE_EVENT_PK            USERS
PERFSTAT                       STATS$PARAMETER_PK             USERS
PERFSTAT                       STATS$INSTANCE_RECOVERY_PK     USERS
PERFSTAT                       STATS$STATSPACK_PARAMETER_PK   USERS
PERFSTAT                       STATS$SHARED_POOL_ADVICE_PK    USERS
PERFSTAT                       STATS$SQL_WORKAREA_HIST_PK     USERS
PERFSTAT                       STATS$PGA_TARGET_ADVICE_PK     USERS
ERP                            XIF195AGREEMENT                CONTRACT
ERP                            XIF179CONTRACT_VERSION         CONTRACT

OWNER                          INDEX_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
ERP                            TPSQL_IDX                      CONTRACT
ERP                            XIF180CONTRACT_VERSION         CONTRACT
ERP                            EFFORT_DATE                    CONTRACT
ERP                            XPKPRINTER_QUEUE               CONTRACT
ERP                            CONSTRUCTIONOBJAFECODEUNIQ     CONTRACT
ERP                            XIF1PRINTER_QUEUE              CONTRACT
ERP                            XIF2PRINTER_QUEUE              CONTRACT
ERP                            XIF3PRINTER_QUEUE              CONTRACT
ERP                            TMP_IDX1
ERP                            TMP_IDX2
ERP                            TMP_IDX3

OWNER                          INDEX_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
ERP                            TMP_IDX4
ERP                            TMP_IDX5
ERP                            XIF181CONTRACT_VERSION         CONTRACT
ERP                            XPKWORK_PLAN_DEPARTMENT        CONTRACT
ERP                            WORKDEPARTMENTUNIQ             CONTRACT
ERP                            XIF1WORK_PLAN_DEPARTMENT       CONTRACT
ERP                            XIF2WORK_PLAN_DEPARTMENT       CONTRACT
ERP                            XIF3WORK_PLAN_DEPARTMENT       CONTRACT
ERP                            XIF4WORK_PLAN_DEPARTMENT       CONTRACT
ERP                            XPKCONTRACT_MAIN_LINK          CONTRACT
ERP                            CONTRACTMAINUNIQ               CONTRACT

OWNER                          INDEX_NAME                     TABLESPACE_NAME
------------------------------ ------------------------------ ------------------------------
ERP                            XIF1CONTRACT_MAIN_LINK         CONTRACT
ERP                            XIF2CONTRACT_MAIN_LINK         CONTRACT
ERP                            XIF3CONTRACT_MAIN_LINK         CONTRACT
ERP                            XIF4CONTRACT_MAIN_LINK         CONTRACT

70 rows selected. 

