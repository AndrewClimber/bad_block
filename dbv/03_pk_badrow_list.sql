
declare
  n number;
  err_msg varchar2(500);
begin
  for Cc in ( select rowid r, document_file_s pk, body b from erp.document_file ) loop
    begin
      n:=dbms_lob.instr(Cc.b,hextoraw('AA25889911'),1,999999);
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into badblock_pk_tmp values(Cc.pk, err_msg, Cc.r);
      commit;
    end;
  end loop;
end;

2303 records
----------------
declare
  n number;
  err_msg varchar2(500);
begin
  for Cc in ( select rowid r, document_file_s pk, body b from CONTRACT_MONEY.document_file ) loop
    begin
      n:=dbms_lob.instr(Cc.b,hextoraw('AA25889911'),1,999999);
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into badblock_pk_tmp_CONTRACT_MONEY values(Cc.pk, err_msg, Cc.r);
      commit;
    end;
  end loop;
end;


0 records
------------------------------

declare
  n1 number;
  n2 number;
  err_msg varchar2(500);
begin
  for Cc in ( select rowid r, atom_s pk, new_blob nb, old_blob ob from nrepl.nrepl_atom ) loop
    begin
      n1:=dbms_lob.instr(Cc.nb,hextoraw('AA25889911'),1,999999);
      n2:=dbms_lob.instr(Cc.ob,hextoraw('AA25889911'),1,999999);
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into badblock_pk_tmp_nrepl_atom values(Cc.pk, err_msg, Cc.r);
      commit;
    end;
  end loop;
end;


794 records
------------------------------------
declare
  n number;
  err_msg varchar2(500);
begin
  for Cc in ( select letter_body_s pk, letter_s l, body b, order_number o from erp.letter_body ) loop
    begin
      n:=instr(Cc.b,'asЖопАsa',1);
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into badblock_pk_tmp_tbl values(Cc.pk, err_msg);
      commit;
    end;
  end loop;
end;



declare
  n number;
  err_msg varchar2(500);
begin
  for Cc in ( select letter_body_s pk, letter_s l, body b, order_number o from erp.letter_body ) loop
    begin
      n:=instr(Cc.b,'asЖопАsa',1);
      insert into badblock_pk_tmp_tbl values(Cc.pk, err_msg);
      commit;
    end;
  end loop;
end;

ERROR at line 1:
ORA-01578: ORACLE data block corrupted (file # 18, block # 501692)
ORA-01110: data file 18: '/mnt/oratest/oradata/docs_020210/contract10.dbf'
ORA-06512: at line 5


----------------------------------------------------

declare
  n number;
  err_msg varchar2(500);
begin
  for Cc in ( select stage_split_btype_s pk, business_type_s bt, 
                     amount am, owner_user_s ou, loader_user_s lu, 
                     description de, load_date ld, stage_version_s sv
              from erp.stage_split_btype
               ) loop
    begin
      --n:=instr(Cc.b,'asЖопАsa',1);
        null;
    exception
    when OTHERS then
      err_msg := SQLERRM;
      insert into badblock_pk_tmp_tbl values(Cc.pk, err_msg);
      commit;
    end;
  end loop;
end;

ERROR at line 1:
ORA-01578: ORACLE data block corrupted (file # 28, block # 329391)
ORA-01110: data file 28: '/mnt/oratest/oradata/docs_020210/contract16.dbf'
ORA-06512: at line 5



-- бэды искать так :
---- 
1. ищем
Отчет DBV :

DBVERIFY - Verification starting : FILE = /mnt/oratest/oradata/docs_020210/contract16.dbf
***
Corrupt block relative dba: 0x070506af (file 28, block 329391)


Запрос из базы :

select rowid, STAGE_SPLIT_BTYPE_S
from erp.stage_split_btype
where dbms_rowid.rowid_block_number(rowid)=329391


Таких записей 126.


2. сохраняем то, что можно сохранить.
create table erp.stage_split_btype_050210 as select * from erp.stage_split_btype
where 1=2;

create table erp.stage_split_btype_rowid_pk as 
select rowid rd, STAGE_SPLIT_BTYPE_S pk
from erp.stage_split_btype
where dbms_rowid.rowid_block_number(rowid)=329391;


insert into erp.stage_split_btype_050210
(
STAGE_SPLIT_BTYPE_S,
BUSINESS_TYPE_S,        
AMOUNT,                 
OWNER_USER_S,           
LOADER_USER_S,          
DESCRIPTION,            
LOAD_DATE,              
STAGE_VERSION_S) 
select 
STAGE_SPLIT_BTYPE_S,
BUSINESS_TYPE_S,        
AMOUNT,                 
OWNER_USER_S,           
LOADER_USER_S,          
DESCRIPTION,            
LOAD_DATE,              
STAGE_VERSION_S
from erp.stage_split_btype
where STAGE_SPLIT_BTYPE_S < 616510500-1200
or STAGE_SPLIT_BTYPE_S > 616522230+1200;

where STAGE_SPLIT_BTYPE_S not in (
select pk from erp.stage_split_btype_rowid_pk
where pk between 
);







DBVERIFY - Verification starting : FILE = /mnt/oratest/oradata/docs_020210/contract10.dbf
Corrupt block relative dba: 0x0487a7bc (file 18, block 501692)

select count(*) --rowid, LETTER_BODY_S
from erp.LETTER_BODY
where dbms_rowid.rowid_block_number(rowid)=501692

COUNT(*)--ROWID,LETTER_BODY_S
-----------------------------
                            5








---------------------------------------






SELECT BYTES,
         (BYTES / 1024) kb, (BYTES / (1024 * 1024)) mb
    FROM SYS.dba_segments
WHERE segment_name='LETTER_BODY' AND owner='ERP'


     BYTES         KB         MB
---------- ---------- ----------
1.1187E+10   10925056      10669



SELECT BYTES,
         (BYTES / 1024) kb, (BYTES / (1024 * 1024)) mb
    FROM SYS.dba_segments
WHERE segment_name='STAGE_SPLIT_BTYPE' AND owner='ERP'

     BYTES         KB         MB
---------- ---------- ----------
  83886080      81920         80



