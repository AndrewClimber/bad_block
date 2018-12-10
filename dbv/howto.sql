1.
с помощью dbv проверим датафайлы.
для этого сгенерируем csh-скрипт.

spool dbv_parallel.csh
set linesize 1000
set pagesize 0
select
 'nohup dbv blocksize=8192 file='||name||' logfile='||
  substr(name,instr(name,'/',-1)+1,length(name))||'.log &' "-- ksh command"
  from v$datafile;
затем прогоним получившийся csh файл и проверим датафайлы.


2. 
в качестве лога после окончания работы dbv_parallel.csh получим файл - nohup.out.
обработаем его для получения номеров бэдблоков.
обрабатывал файл с помощью потокового редактора sed :

cat nohup.out | sed 's/DBV-00200: Block, dba//' | sed 's/, already marked corrupted//' | sed 's/DBV-00200://' | sed 's/Block, dba//' | sed 's/, already marked corrupted//' | sed '/^$/d' | sed 's/^[ \t]*//'  > bad_blk.txt
удалил лишние символы и пустые строки. Получил список номеров битых блоков.

3.
создадим таблицу 
create table bad_blk_list (bb# number);

затем сформируем sql-скрипт 
templ badblock_list_tmp.tpl bad_blk.txt bad_blk.sql
впрочем эту операцию можно сделать и с помощью sqlloader-а.

прогоним скрипт в базе.
@bad_blk.sql

select count(*) from bad_blk_list;

  COUNT(*)
----------
    154976

в данной таблице теперь лежит номер в котором закодирован номер датафайла и адрес бэд-блока в этом датафайле.
	

4.
создадим таблицу в которую будут заносится данные : адрес(смещение) бэд-блока и номер датафайла.
create table bad_obj_list (bb# number, fi# number);

!!! перекодируем данные из таблицы bad_blk_list в формат новой таблицы.
хотя все это можно было бы сделать и на предыдущем этапе п/п №3.

declare
 fil# number;
 blk# number;
begin
  for Cc in ( select bb# from bad_blk_list ) loop
    fil# := dbms_utility.data_block_address_file(Cc.bb#);
    blk# := dbms_utility.data_block_address_block(Cc.bb#);
    insert into bad_obj_list values(blk#,fil#);
  end loop;
  commit;
end;

select count(*) from bad_obj_list;

  COUNT(*)
----------
    154976

select count(*),fi# from bad_obj_list group by fi#;

  COUNT(*)        FI#
---------- ----------
     29914         37
    125062         38


select file#,name from v$datafile where file# in (37,38);

     FILE# NAME
---------- -----------------------------------------------------------------------
        37 /data/oradata/docs/nrepl09.dbf
        38 /data/oradata/docs/contract23.dbf



5.

-- определим на основе информации из таблицы bad_obj_list имена и типы объектов БД, в которых находятся битые блоки.

select e.tablespace_name,e.owner,e.segment_name,e.segment_type, c.bb#
    from dba_extents e,  
     bad_obj_list c
    where c.fi# in (37,38) and
    (e.file_id=c.fi# and c.bb# between e.block_id and e.block_id+e.blocks-1)
    or
    (e.file_id=c.fi# and c.bb#+e.blocks-1 between e.block_id and e.block_id+e.blocks-1);




COUNT(*) TABLESPACE_NAME    OWNER  SEGMENT_NAME               SEGMENT_TYPE      
-------- -------------------- ---- -------------------------- ------------------
  1023 NREPL                NREPL  TRANUNIQ                   INDEX              
  7167 NREPL                NREPL  NREPL_ATOM                 TABLE              
  4036 NREPL                NREPL  XIF8NREPL_ATOM             INDEX              
  1023 NREPL                NREPL  NREPL_TRANSACTION          TABLE              
  1023 NREPL                NREPL  XIF5NREPL_OPERATION        INDEX              
  1023 NREPL                NREPL  XPKNREPL_TRANSACTION       INDEX              
 45549 NREPL                NREPL  SYS_LOB0000024771C00012$$  LOBSEGMENT         
  1023 CONTRACT             ERP    ERP_AUDIT                  TABLE              
 21015 CONTRACT             ERP    LETTER_BODY                TABLE              
   127 CONTRACT             ERP    XFKPRINT_LOG1              INDEX              
   127 CONTRACT             ERP    CHECKSTAGESPLIT            INDEX              
   127 CONTRACT             ERP    XIF1TOURNIQUET_EVENT       INDEX              
   127 CONTRACT             ERP    XIF3TOURNIQUET_EVENT       INDEX              
   127 CONTRACT             ERP    XFKSTAGE_SPLIT_BTYPE1      INDEX              
   127 CONTRACT             ERP    XFKSTAGE_SPLIT_BTYPE2      INDEX              
225254 CONTRACT             ERP    SYS_LOB0000025033C00006$$  LOBSEGMENT         


возможно этот запрос некоректен и выгребает лишние данные.
вот этот запрос показывает иную картину . И к тому же кол-во битых блоков и их распределение по датафайлам 
совпадает с данными запроса из п/п №4 :

select count(*),e.tablespace_name,e.owner,e.segment_name,e.segment_type --, c.bb#
    from dba_extents e,  
     bad_obj_list c
    where c.fi# in (37,38) and
    (e.file_id=c.fi# and c.bb# between e.block_id and e.block_id+e.blocks-1)
group by e.tablespace_name,e.owner,e.segment_name,e.segment_type  

COUNT(*) TABLESPACE_NAME  OWNER  SEGMENT_NAME               SEGMENT_TYPE      
-------- ---------------- ------ -------------------------- ------------------
   29914 NREPL            NREPL  SYS_LOB0000024771C00012$$  LOBSEGMENT         
  125062 CONTRACT         ERP    SYS_LOB0000025033C00006$$  LOBSEGMENT         



посмотрим к каким таблицам относятся эти блобы.

  select owner,table_name
  from dba_lobs
  where segment_name in
  ('SYS_LOB0000025033C00006$$','SYS_LOB0000024771C00012$$')

OWNER                          TABLE_NAME
------------------------------ ------------------------------
NREPL                          NREPL_ATOM
ERP                            DOCUMENT_FILE




6.
-- создадим таблицу в которую запишем первичные ключи сбойных документов.

create table bad_block_pk ( pk number, msg varchar2(4000) );

declare
  n number;
  err_msg varchar2(500);
begin
  for Cc in ( select document_file_s pk, body b from erp.document_file ) loop
    begin
      n:=dbms_lob.instr(Cc.b,hextoraw('AA25889911'),1,999999);
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into bad_block_pk values(Cc.pk, err_msg);
      commit;
    end;
  end loop;
end;


select count(*) from bad_block_pk;

  COUNT(*)
----------
      2027

7.

теперь можно сделать отчет и вывести испорченные документы.

select d.document_file_s, d.name, d.source_name, d.creation_date
from erp.document_file d, bad_block_pk b
where b.pk=d.document_file_s



--------------------------------------------------------------------------------------------------
-------- ЛЕЧИМ  ERP.DOCUMENT_FILE
--------------------------------------------------------------------------------------------------
1. 

 обнуляем битые блобы.

update erp.document_file set body =hextoraw('DAA25889911') where document_file_s in (
 select pk from bad_block_pk );

2.
Определим размер блоба в erp.document_file.

SELECT ROUND (SUM (DBMS_LOB.getlength (a.body)) / (1024 * 1024 * 1024), 2) gbytes
 FROM erp.document_file a;

    GBYTES
----------
     59.42

-- создадим таблспейс для блобов.
set timing on
-- засечем во сколько начали - 14:20

CREATE TABLESPACE contract_lob DATAFILE 
  '/data/oradata/docs/contract_lob01.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob02.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob03.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob04.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob05.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob06.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob07.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob08.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob09.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob10.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob11.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob12.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob13.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob14.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob15.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob16.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob17.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob18.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob19.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob20.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_lob21.dbf' SIZE 4096M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;

-- засечем во сколько закончили - 
Elapsed: 00:32:01.28
-- 14:55


!!!!!!!!!!!!!!!! СОЗДАТЬ ТАБЛСПЕЙС CONTRACT_TAB !!!
-- начало - 18:36
-- создадим таблспейсы под индексы и данные.
CREATE TABLESPACE contract_tab DATAFILE 
  '/data/oradata/docs/contract_tab01.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_tab02.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_tab03.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/contract_tab04.dbf' SIZE 4096M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;
-- закончили 18:44
Elapsed: 00:06:45.55


-- начали 18:44
CREATE TABLESPACE contract_idx DATAFILE 
  '/data/oradata/docs/contract_idx01.dbf' SIZE 4096M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;
-- закончили 18:46
Elapsed: 00:01:42.28



3. 
-- перенесем блобы во вновьсозданный таблспейс.
-- начал в 14:57
ALTER TABLE ERP.document_file MOVE
TABLESPACE contract_tab ---- !!!! 
 LOB(body) STORE AS contract_body_lob_seg0
 (TABLESPACE contract_lob);
-- закончил в 17:46
Elapsed: 02:37:15.16


4.
-- перенос таблиц и индексов в другой таблспейс.

-- посмотрим какие типы сегментов лежат в таблспейсе CONTRACT.
select count(*),segment_type from dba_segments
where tablespace_name='CONTRACT'
group by segment_type;

  COUNT(*) SEGMENT_TYPE
---------- ------------------
      1163 INDEX
         6 LOBINDEX
         6 LOBSEGMENT
       310 TABLE
         1 TEMPORARY


-- узнаем какие типы данных хрянятся в CONTRACT.
select count(*),c.data_type
 from dba_tab_columns c, dba_tables t
 where c.table_name=t.table_name and
 c.owner=t.owner and t.tablespace_name='CONTRACT'
group by c.data_type;

  COUNT(*) DATA_TYPE
---------- ----------------------------------------------------------------------------------------------------------
         6 BLOB
         2 CHAR
       317 DATE
         6 LONG
         1 LONG RAW
      1531 NUMBER
         2 RAW
       780 VARCHAR2


-- узнаем в каких таблицах имеются блобы.
select t.owner,t.table_name,c.column_name
from dba_tables t, dba_tab_columns c
 where c.table_name=t.table_name and
 c.owner=t.owner and 
 t.tablespace_name='CONTRACT' and
 c.data_type='BLOB';

OWNER                          TABLE_NAME                     COLUMN_NAME
------------------------------ ------------------------------ ------------------------------
CONTRACT_MONEY                 CREATE$JAVA$LOB$TABLE          LOB
CONTRACT_MONEY                 DOCUMENT_FILE                  BODY
CONTRACT_MONEY                 TEMPLATE                       BODY
ERP                            CREATE$JAVA$LOB$TABLE          LOB
ERP                            DOCUMENT_FILE                  BODY
ERP                            TEMPLATE                       BODY

-- перенесем блобы во вновьсозданный таблспейс.
-- начал в 
ALTER TABLE CONTRACT_MONEY.CREATE$JAVA$LOB$TABLE MOVE
TABLESPACE contract
 LOB(lob) STORE AS java_cm_body_lob_seg0
 (TABLESPACE contract_lob);
-- закончил в махом
Elapsed: 00:00:01.27

-- перенесем блобы во вновьсозданный таблспейс.
-- начал в 17:47
ALTER TABLE CONTRACT_MONEY.DOCUMENT_FILE MOVE
TABLESPACE contract
 LOB(body) STORE AS body_lob_seg1
 (TABLESPACE contract_lob);
-- закончил в  17:51
Elapsed: 00:01:34.01

-- перенесем блобы во вновьсозданный таблспейс.
-- начал в 
ALTER TABLE CONTRACT_MONEY.TEMPLATE MOVE
TABLESPACE contract
 LOB(body) STORE AS body_templ_lob_seg
 (TABLESPACE contract_lob);
-- закончил в 
Elapsed: 00:00:01.61


-- перенесем блобы во вновьсозданный таблспейс.
-- начал в 
ALTER TABLE erp.CREATE$JAVA$LOB$TABLE MOVE
TABLESPACE contract
 LOB(lob) STORE AS java_body_lob_seg0
 (TABLESPACE contract_lob);
-- закончил в 
Elapsed: 00:00:00.84


-- перенесем блобы во вновьсозданный таблспейс.
-- начал в 
ALTER TABLE erp.TEMPLATE MOVE
TABLESPACE contract
 LOB(body) STORE AS body_templ_lob_seg1
 (TABLESPACE contract_lob);
-- закончил в 
Elapsed: 00:00:00.66




-- узнаем в каких таблицах имеются RAW и LONG RAW.
select t.owner,t.table_name,c.column_name,c.data_type
from dba_tables t, dba_tab_columns c
 where c.table_name=t.table_name and
 c.owner=t.owner and 
 t.tablespace_name='CONTRACT' and
 c.data_type like '%RAW';

OWNER                          TABLE_NAME                     COLUMN_NAME                    DATA_TYPE
------------------------------ ------------------------------ ------------------------------ ----------------------------------------------------------------------------------------------------------
CONTRACT_MONEY                 JAVA$CLASS$MD5$TABLE           MD5                            RAW
JIRA                           PROPERTYDATA                   PROPERTYVALUE                  LONG RAW
ERP                            JAVA$CLASS$MD5$TABLE           MD5                            RAW



-- узнаем в каких таблицах имеются LONG.
select t.owner,t.table_name,c.column_name
from dba_tables t, dba_tab_columns c
 where c.table_name=t.table_name and
 c.owner=t.owner and 
 t.tablespace_name='CONTRACT' and
 c.data_type='LONG';

OWNER                          TABLE_NAME                     COLUMN_NAME
------------------------------ ------------------------------ ------------------------------
SYSTEM                         QUEST_COM_PRODUCTS             DEINSTALL_SCRIPT
CONTRACT_USER                  PLAN_TABLE                     OTHER
CONTRACT_MONEY                 TOAD_PLAN_TABLE                OTHER
ERP_BUDGET                     PLAN_TABLE                     OTHER
ERP                            PLAN_TABLE                     OTHER
ERP                            TOAD_PLAN_TABLE                OTHER


-- таблицы с архаичным типом long не переносятся . Поэтому просто дропнем их. Тем более это таблицы легко без потери данных можно 
-- позднее пересоздать.
drop table system.quest_com_user_privileges;
drop table system.quest_com_product_privs;
drop table system.quest_com_products_used_by;
drop table system.quest_com_users;
drop table system.QUEST_COM_PRODUCTS;

drop table CONTRACT_USER.plan_table;
drop table CONTRACT_MONEY.TOAD_plan_table;
drop table erp_budget.plan_table;
drop table erp.plan_table;
drop table erp.TOAD_plan_table;

drop table jira.propertydata;


5. 
Перенесем другие типы сегментов. Не блобы.


-- вычислим общий размер таблицы.
SELECT sum(BYTES / (1024 * 1024 * 1024)) Gb
    FROM dba_segments where tablespace_name='CONTRACT' and segment_type='TABLE';

        GB
----------
13.1573486


-- вычислим общий размер индексов
SELECT sum(BYTES / (1024 * 1024 * 1024)) Gb
    FROM dba_segments where tablespace_name='CONTRACT' and segment_type='INDEX';

        GB
----------
 3.1315918





6.
-- сформируем скрипты для переноса.
set pagesize 0
set linesize 1000
spool move_tbl.sql
select 'ALTER TABLE '||owner||'.'||table_name||' MOVE TABLESPACE contract_tab;'
from dba_tables
where 
tablespace_name='CONTRACT';
spool off

spool move_tbl.log
@move_tbl.sql
spool off


set pagesize 0
set linesize 1000
spool move_idx.sql
select 'ALTER INDEX '||owner||'.'||index_name||' REBUILD  TABLESPACE contract_idx;'
from
dba_indexes 
where 
tablespace_name='CONTRACT';
spool off


spool move_idx.log
@move_idx.sql
spool off



7. Проверки

-- проверим валидность индексов.

select count(*),status 
from dba_indexes 
group by status;

  COUNT(*) STATUS
---------- --------
        25 N/A
      1819 VALID

-- проверим осталось-ли что-то еще в таблспейсе CONTRACT.

select count(*) from dba_segments where tablespace_name='CONTRACT';
  COUNT(*)
----------
         0


-- проверим на бэдблоки
select distinct e.tablespace_name,e.owner,e.segment_name,e.segment_type --,c.block#--,e.block_id
    from dba_extents e,  --v$database_block_corruption c 
     v$database_block_corruption c 
    where --c.file# in (37,38) and
    (e.file_id=c.file# and c.block# between e.block_id and e.block_id+e.blocks-1)
    or
    (e.file_id=c.file# and c.block#+c.blocks-1 between e.block_id and e.block_id+e.blocks-1);

TABLESPACE_NAME                OWNER                          SEGMENT_NAME                                                                      SEGMENT_TYPE
------------------------------ ------------------------------ --------------------------------------------------------------------------------- ------------------
NREPL                          NREPL                          SYS_LOB0000024771C00012$$                                                         LOBSEGMENT


-- еще раз проверим. но по другому.
select * from v$database_block_corruption;

     FILE#     BLOCK#     BLOCKS CORRUPTION_CHANGE# CORRUPTIO
---------- ---------- ---------- ------------------ ---------
         7     178839          1                  0 FRACTURED
         7     333058          1                  0 FRACTURED
        37      92916       1301         1.3338E+12 LOGICAL
        37      96265       8192         1.3341E+12 LOGICAL
        37     122889       8192         1.3343E+12 LOGICAL
        37     132105       8192         1.3343E+12 LOGICAL
        37     141321       4038         1.3347E+12 LOGICAL
        38      78064       4889         1.3338E+12 LOGICAL
        38      91657       8192         1.3341E+12 LOGICAL
        38     101001      16384         1.3341E+12 LOGICAL
        38     117641       8192         1.3343E+12 LOGICAL

     FILE#     BLOCK#     BLOCKS CORRUPTION_CHANGE# CORRUPTIO
---------- ---------- ---------- ------------------ ---------
        38     134281      16384         1.3343E+12 LOGICAL
        38     150793       5759         1.3343E+12 LOGICAL
        38     156553       2432         1.3343E+12 LOGICAL
        38     159113      24576         1.3343E+12 LOGICAL
        38     191881      16384         1.3347E+12 LOGICAL
        38     208393      16384         1.3347E+12 LOGICAL
        38     225929       5376         1.3348E+12 LOGICAL
        38     231306        111         1.3348E+12 LOGICAL


8.
-- убьем таблспейс.
DROP TABLESPACE CONTRACT;

-- удалим датафайлы в файловой системе.
rm -f contract01.dbf contract02.dbf contract03.dbf contract04.dbf contract21.dbf contract22.dbf contract23.dbf
rm -f contract12.dbf contract05.dbf contract06.dbf contract07.dbf contract08.dbf contract09.dbf contract10.dbf contract11.dbf
rm -f contract13.dbf contract14.dbf contract15.dbf contract16.dbf contract17.dbf contract18.dbf contract19.dbf contract20.dbf


--------------------------------------------------------------------------------------------------
-------- ЛЕЧИМ  NREPL.NREPL_ATOM
--------------------------------------------------------------------------------------------------
0.
create table bad_block_pk_nrepl_atom ( pk number, msg varchar2(4000), tyfld char(3) );


declare
  n1 number;
  n2 number;
  err_msg varchar2(500);
begin
  for Cc in ( select atom_s pk, new_blob nb, old_blob ob from nrepl.nrepl_atom ) loop
    begin
      n1:=dbms_lob.instr(Cc.nb,hextoraw('AA25889911'),1,999999);      
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into bad_block_pk_nrepl_atom values(Cc.pk, err_msg, 'new');
      commit;
    end;
    begin
      n2:=dbms_lob.instr(Cc.ob,hextoraw('AA25889911'),1,999999);      
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into bad_block_pk_nrepl_atom values(Cc.pk, err_msg, 'old');
      commit;
    end;
  end loop;
end;



SQL> select count(*) from bad_block_pk_nrepl_atom;

  COUNT(*)
----------
       794

SQL> select count(*),tyfld from bad_block_pk_nrepl_atom
  2  group by tyfld;

  COUNT(*) TYF
---------- ---
       794 new





select d.atom_s, d.operation_s, d.column_name, d.column_type
from nrepl.nrepl_atom d, bad_block_pk_nrepl_atom b
where d.atom_s=b.pk



1.


-- обнуляем битые блобы.

set timing on
update nrepl.nrepl_atom set new_blob =hextoraw('DAA25889911') where atom_s in (
 select pk from bad_block_pk_nrepl_atom );

2.
Определим размер блоба .

SELECT ROUND (SUM (DBMS_LOB.getlength (a.new_blob)) / (1024 * 1024 * 1024), 2) gbytes_new,
       ROUND (SUM (DBMS_LOB.getlength (a.old_blob)) / (1024 * 1024 * 1024), 2) gbytes_old
 FROM nrepl.nrepl_atom a;

GBYTES_NEW GBYTES_OLD
---------- ----------
     15.38          0

Elapsed: 00:07:19.94




-- посмотрим какие типы сегментов лежат в таблспейсе.
select count(*),segment_type from dba_segments
where tablespace_name='NREPL'
group by segment_type;

  COUNT(*) SEGMENT_TYPE
---------- ------------------
        18 INDEX
         2 LOBINDEX
         2 LOBSEGMENT
         8 TABLE





-- узнаем какие типы данных хрянятся в NREPL.
select count(*),c.data_type
 from dba_tab_columns c, dba_tables t
 where c.table_name=t.table_name and
 c.owner=t.owner and t.tablespace_name='NREPL'
group by c.data_type;
  COUNT(*) DATA_TYPE
---------- ----------------------------------------------------------------------------------------------------------
         2 BLOB
         3 DATE
        18 NUMBER
        28 VARCHAR2




-- узнаем в каких таблицах имеются блобы.
select t.owner,t.table_name,c.column_name
from dba_tables t, dba_tab_columns c
 where c.table_name=t.table_name and
 c.owner=t.owner and 
 t.tablespace_name='NREPL' and
 c.data_type='BLOB';

OWNER                          TABLE_NAME                     COLUMN_NAME
------------------------------ ------------------------------ ------------------------------
NREPL                          NREPL_ATOM                     OLD_BLOB
NREPL                          NREPL_ATOM                     NEW_BLOB


-- вычислим общий размер таблицы.
SELECT sum(BYTES / (1024 * 1024 * 1024)) Gb
    FROM dba_segments where tablespace_name='NREPL' and segment_type='TABLE';
        GB
----------
5.66436768



-- вычислим общий размер индексов
SELECT sum(BYTES / (1024 * 1024 * 1024)) Gb
    FROM dba_segments where tablespace_name='NREPL' and segment_type='INDEX';

        GB
----------
5.15594482


3. 
-- создадим таблспейсы под индексы и данные.
CREATE TABLESPACE nrepl_tab DATAFILE 
  '/data/oradata/docs/nrepl_tab01.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/nrepl_tab02.dbf' SIZE 4096M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;

Elapsed: 00:02:39.18



CREATE TABLESPACE nrepl_idx DATAFILE 
  '/data/oradata/docs/nrepl_idx01.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/nrepl_idx02.dbf' SIZE 4096M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;

Elapsed: 00:02:32.97


CREATE TABLESPACE nrepl_lob DATAFILE 
  '/data/oradata/docs/nrepl_lob01.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/nrepl_lob02.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/nrepl_lob03.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/data/oradata/docs/nrepl_lob04.dbf' SIZE 4096M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;
ALTER TABLESPACE NREPL_LOB ADD DATAFILE '/data/oradata/docs/nrepl_lob05.dbf' SIZE 4096M AUTOEXTEND OFF;

Elapsed: 00:05:22.40

4.

-- расширим NREPL. 
ALTER TABLESPACE NREPL ADD DATAFILE '/data/oradata/docs/nrepl_temp.dbf' SIZE 4096M REUSE AUTOEXTEND OFF;
ALTER TABLESPACE NREPL ADD DATAFILE '/data/oradata/docs/nrepl_temp01.dbf' SIZE 4096M REUSE AUTOEXTEND OFF;



-- перенесем объекты в новые таблспейсы.

-- перенесем блобы во вновьсозданный таблспейс.

ALTER TABLE nrepl.nrepl_atom MOVE
TABLESPACE nrepl_tab --- !!!!
 LOB(NEW_BLOB) STORE AS nrepl_lob_seg2
 (TABLESPACE nrepl_lob);

Elapsed: 00:56:48.81


ALTER TABLE nrepl.nrepl_atom MOVE
TABLESPACE nrepl_tab -- !!!
 LOB(OLD_BLOB) STORE AS nrepl_lob_seg1
 (TABLESPACE nrepl_lob);

Elapsed: 00:08:42.28




5.
-- перенесем таблицы и индексы.

-- сформируем скрипты для переноса.
set pagesize 0
set linesize 1000
spool move_tbl.sql
select 'ALTER TABLE '||owner||'.'||table_name||' MOVE TABLESPACE nrepl_tab;'
from dba_tables
where 
tablespace_name='NREPL';
spool off

spool move_tbl.log
@move_tbl.sql
spool off


set pagesize 0
set linesize 1000
spool move_idx.sql
select 'ALTER INDEX '||owner||'.'||index_name||' REBUILD  TABLESPACE nrepl_idx;'
from
dba_indexes 
where 
tablespace_name='NREPL';
spool off


spool move_idx.log
@move_idx.sql
spool off



6. Проверки

-- проверим валидность индексов.

select count(*),status 
from dba_indexes 
group by status;



-- проверим осталось-ли что-то еще в таблспейсе NREPL.

select count(*) from dba_segments where tablespace_name='NREPL';


-- проверим на бэдблоки
select distinct e.tablespace_name,e.owner,e.segment_name,e.segment_type --,c.block#--,e.block_id
    from dba_extents e,  --v$database_block_corruption c 
     v$database_block_corruption c 
    where --c.file# in (37,38) and
    (e.file_id=c.file# and c.block# between e.block_id and e.block_id+e.blocks-1)
    or
    (e.file_id=c.file# and c.block#+c.blocks-1 between e.block_id and e.block_id+e.blocks-1);


TABLESPACE_NAME                OWNER                          SEGMENT_NAME                                                                      SEGMENT_TYPE
------------------------------ ------------------------------ --------------------------------------------------------------------------------- ------------------
NREPL_IDX                      NREPL                          XPKNREPL_ATOM                                                                     INDEX



select count(*),e.tablespace_name,e.owner,e.segment_name,e.segment_type --, c.bb#
    from dba_extents e,  
     bad_obj_list c
    where --c.fi# in (37,38) and
    (e.file_id=c.fi# and c.bb# between e.block_id and e.block_id+e.blocks-1)
group by e.tablespace_name,e.owner,e.segment_name,e.segment_type;  




 
ALTER INDEX nrepl.XPKNREPL_ATOM REBUILD tablespace nrepl_idx online;


ALTER TABLE nrepl.nrepl_atom enable CONSTRAINT xpknrepl_atom; 



CREATE UNIQUE INDEX xpknrepl_atom ON nrepl.nrepl_atom
  (
    atom_s                          ASC
  )
  PCTFREE     10
  INITRANS    2
  MAXTRANS    255
  TABLESPACE  nrepl_idx
  STORAGE   (
    INITIAL     65536
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
/



-- еще раз проверим. но по другому.
select * from v$database_block_corruption;



7.
-- убьем таблспейс.
DROP TABLESPACE NREPL;

8.
-- удалим датафайлы в файловой системе.
rm -f nrepl01.dbf nrepl02.dbf nrepl03.dbf nrepl04.dbf nrepl05.dbf nrepl06.dbf nrepl07.dbf nrepl08.dbf nrepl09.dbf
rm -f nrepl_temp01.dbf nrepl_temp.dbf

-------------------------------------------------------------------------------------------------------------------------
 ПРОВЕРКИ БД
-------------------------------------------------------------------------------------------------------------------------
1.
select * from v$database_block_corruption;


     FILE#     BLOCK#     BLOCKS CORRUPTION_CHANGE# CORRUPTIO
---------- ---------- ---------- ------------------ ---------
         7     178839          1                  0 FRACTURED
         7     333058          1                  0 FRACTURED
        37      92916       1301         1.3338E+12 LOGICAL
        37      96265       8192         1.3341E+12 LOGICAL
        37     122889       8192         1.3343E+12 LOGICAL
        37     132105       8192         1.3343E+12 LOGICAL
        37     141321       4038         1.3347E+12 LOGICAL
        38      78064       4889         1.3338E+12 LOGICAL
        38      91657       8192         1.3341E+12 LOGICAL
        38     101001      16384         1.3341E+12 LOGICAL
        38     117641       8192         1.3343E+12 LOGICAL
        38     134281      16384         1.3343E+12 LOGICAL
        38     150793       5759         1.3343E+12 LOGICAL
        38     156553       2432         1.3343E+12 LOGICAL
        38     159113      24576         1.3343E+12 LOGICAL
        38     191881      16384         1.3347E+12 LOGICAL
        38     208393      16384         1.3347E+12 LOGICAL
        38     225929       5376         1.3348E+12 LOGICAL
        38     231306        111         1.3348E+12 LOGICAL

19 rows selected.

-- проверим базу данных на уровне блоков с помощью RMAN-а.
2. Проверка всей базы данных.
RUN {
ALLOCATE CHANNEL c1 TYPE DISK;
BACKUP CHANNEL c1 VALIDATE CHECK LOGICAL DATABASE; }




3.

select * from v$database_block_corruption;

     FILE#     BLOCK#     BLOCKS CORRUPTION_CHANGE# CORRUPTIO
---------- ---------- ---------- ------------------ ---------
        37      92916       1301         1.3338E+12 LOGICAL
        37      96265       8192         1.3341E+12 LOGICAL
        37     122889       8192         1.3343E+12 LOGICAL
        37     132105       8192         1.3343E+12 LOGICAL
        37     141321       4038         1.3347E+12 LOGICAL
        38      78064       4889         1.3338E+12 LOGICAL
        38      91657       8192         1.3341E+12 LOGICAL
        38     101001      16384         1.3341E+12 LOGICAL
        38     117641       8192         1.3343E+12 LOGICAL
        38     134281      16384         1.3343E+12 LOGICAL
        38     150793       5759         1.3343E+12 LOGICAL
        38     156553       2432         1.3343E+12 LOGICAL
        38     159113      24576         1.3343E+12 LOGICAL
        38     191881      16384         1.3347E+12 LOGICAL
        38     208393      16384         1.3347E+12 LOGICAL
        38     225929       5376         1.3348E+12 LOGICAL
        38     231306        111         1.3348E+12 LOGICAL

17 rows selected.


4.
-- а файликов-то за номером 37 и 38 нет.
select file#,name from v$datafile where file# in (37,38);

no rows selected

5.

-- наличие инфы в v$database_block_corruption напрягает.
-- инфа хранится в контрольфайле.
-- поэтому надо его пересоздать.
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

RECOVER DATABASE UNTIL CANCEL;

ALTER DATABASE OPEN RESETLOGS;

ALTER TABLESPACE TEMP ADD TEMPFILE '/data/oradata/docs/temp03.dbf'
     SIZE 1024M REUSE AUTOEXTEND OFF;

ALTER TABLESPACE TEMP ADD TEMPFILE '/data/oradata/docs/temp04.dbf'
     SIZE 1024M REUSE AUTOEXTEND OFF;


-- и после этого левая инфа о битых блоках вычистилась.
select * from v$database_block_corruption;

no rows selected


-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
CREATE TABLE jira.propertydata
    (id                             NUMBER(18,0) NOT NULL,
    propertyvalue                  LONG RAW)
  PCTFREE     10
  PCTUSED     40
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  contract_tab
  STORAGE   (
    INITIAL     1064960
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  NOMONITORING
/



-- Constraints for PROPERTYDATA

ALTER TABLE jira.propertydata
ADD CONSTRAINT pk_propertydata PRIMARY KEY (id)
USING INDEX
  PCTFREE     10
  INITRANS    2
  MAXTRANS    255
  TABLESPACE  contract_idx
  STORAGE   (
    INITIAL     1064960
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
/



CREATE TABLE plan_table
    (statement_id                   VARCHAR2(30),
    timestamp                      DATE,
    remarks                        VARCHAR2(80),
    operation                      VARCHAR2(30),
    options                        VARCHAR2(255),
    object_node                    VARCHAR2(128),
    object_owner                   VARCHAR2(30),
    object_name                    VARCHAR2(30),
    object_instance                NUMBER(*,0),
    object_type                    VARCHAR2(30),
    optimizer                      VARCHAR2(255),
    search_columns                 NUMBER,
    id                             NUMBER(*,0),
    parent_id                      NUMBER(*,0),
    position                       NUMBER(*,0),
    cost                           NUMBER(*,0),
    cardinality                    NUMBER(*,0),
    bytes                          NUMBER(*,0),
    other_tag                      VARCHAR2(255),
    partition_start                VARCHAR2(255),
    partition_stop                 VARCHAR2(255),
    partition_id                   NUMBER(*,0),
    other                          LONG,
    distribution                   VARCHAR2(30),
    cpu_cost                       NUMBER(*,0),
    io_cost                        NUMBER(*,0),
    temp_space                     NUMBER(*,0),
    access_predicates              VARCHAR2(4000),
    filter_predicates              VARCHAR2(4000))
  PCTFREE     10
  PCTUSED     40
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  contract_tab
  STORAGE   (
    INITIAL     65536
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  NOMONITORING
/

-- Grants for Table
GRANT ALTER ON plan_table TO public
/
GRANT DELETE ON plan_table TO public
/
GRANT INDEX ON plan_table TO public
/
GRANT INSERT ON plan_table TO public
/
GRANT SELECT ON plan_table TO public
/
GRANT UPDATE ON plan_table TO public
/
GRANT REFERENCES ON plan_table TO public
/
GRANT ON COMMIT REFRESH ON plan_table TO public
/
GRANT QUERY REWRITE ON plan_table TO public
/
GRANT DEBUG ON plan_table TO public
/
GRANT FLASHBACK ON plan_table TO public
/


CREATE TABLE toad_plan_table
    (statement_id                   VARCHAR2(32),
    timestamp                      DATE,
    remarks                        VARCHAR2(80),
    operation                      VARCHAR2(30),
    options                        VARCHAR2(30),
    object_node                    VARCHAR2(128),
    object_owner                   VARCHAR2(30),
    object_name                    VARCHAR2(30),
    object_instance                NUMBER,
    object_type                    VARCHAR2(30),
    search_columns                 NUMBER,
    id                             NUMBER,
    cost                           NUMBER,
    parent_id                      NUMBER,
    position                       NUMBER,
    cardinality                    NUMBER,
    optimizer                      VARCHAR2(255),
    bytes                          NUMBER,
    other_tag                      VARCHAR2(255),
    partition_id                   NUMBER,
    partition_start                VARCHAR2(255),
    partition_stop                 VARCHAR2(255),
    distribution                   VARCHAR2(30),
    other                          LONG)
  PCTFREE     10
  PCTUSED     40
  INITRANS    1
  MAXTRANS    255
  TABLESPACE  contract_tab
  STORAGE   (
    INITIAL     81920
    MINEXTENTS  1
    MAXEXTENTS  2147483645
  )
  NOCACHE
  NOMONITORING
/

-- Grants for Table
GRANT SELECT ON toad_plan_table TO contract_user
/




---- затраченное время.

1.
-- создадим таблспейс для блобов. CONTRACT
Elapsed: 00:32:01.28

2. СОЗДАТЬ ТАБЛСПЕЙС CONTRACT_TAB !!!
Elapsed: 00:06:45.55

CREATE TABLESPACE contract_idx DATAFILE 
Elapsed: 00:01:42.28

3.
-- перенесем блобы во вновьсозданный таблспейс.
Elapsed: 02:37:15.16

4.
-- перенос таблиц и индексов в другой таблспейс.
Elapsed: 01:37:15.16

5.
ЛЕЧИМ  NREPL.NREPL_ATOM
-- создадим таблспейсы под индексы и данные.
Elapsed: 00:02:39.18
Elapsed: 00:02:32.97
Elapsed: 00:05:22.40

6.
-- перенесем блобы во вновьсозданный таблспейс.
Elapsed: 00:56:48.81
Elapsed: 00:08:42.28

7.
-- перенесем таблицы и индексы.
Elapsed: 01:08:42.28

8.
-- проверим базу данных на уровне блоков с помощью RMAN-а.
Elapsed: 03:50:42.28


ИТОГО (без учета времени на предварительный холодный бэкап базы) : 11 часов.
