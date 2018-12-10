
1.

SELECT 'CREATE TABLE DUMMY_BB PCTFREE 99 PCTUSED 1 STORAGE (INITIAL '
|| bytes
|| ' NEXT ' 
|| bytes
|| ' PCTINCREASE 0) TABLESPACE contract as select * from DBA_DATA_FILES;'
FROM dba_free_space a
WHERE a.file_id=38
and 
78064
BETWEEN a.BLOCK_ID and a.BLOCK_ID + a.BLOCKS - 1;

------ 



CREATE TABLE DUMMY_BB PCTFREE 99 PCTUSED 1 STORAGE (INITIAL 67108864 NEXT 67108864 PCTINCREASE 0) TABLESPACE contract 
as select * from DBA_DATA_FILES;



--- проверка
 select segment_name,tablespace_name from user_segments
where segment_name='DUMMY_BB' ;




2.


declare
CURSOR c IS
SELECT 'alter table DUMMY_BB allocate extent (size '
|| bytes
|| ' datafile '
|| '''/mnt/oratest/oradata/docs_020210/contract23.dbf'''
|| ')' ss
FROM dba_free_space a,
bad_obj_list b WHERE a.file_id=38 and b.block_addr BETWEEN a.BLOCK_ID and a.BLOCK_ID + a.BLOCKS - 1;
begin
FOR r IN c LOOP
EXECUTE IMMEDIATE r.ss;
END LOOP;
END;
END;
/



CREATE OR REPLACE TRIGGER corrupt_trigger
AFTER INSERT ON DUMMY_BB
REFERENCING OLD AS p_old NEW AS new_p
FOR EACH ROW
DECLARE
corrupt EXCEPTION;
BEGIN
  IF (dbms_rowid.rowid_block_number(:new_p.rowid)=&blocknumber) THEN
    RAISE corrupt;
  END IF;
EXCEPTION
WHEN corrupt THEN
  RAISE_APPLICATION_ERROR(-20000, 'Corrupt block has been formatted');
END;
/



DECLARE
k NUMBER := 0;
BEGIN
 WHILE (k < 500) LOOP
   insert into DUMMY_BB select * from DBA_DATA_FILES;
   commit;
   k := k + 1;
 END LOOP;
END;
/


DECLARE
  TYPE DBA_DATA_FILES_REC IS RECORD (
   FILE_NAME       DBA_DATA_FILES.FILE_NAME%TYPE,      
   FILE_ID         DBA_DATA_FILES.FILE_ID%TYPE,        
   TABLESPACE_NAME DBA_DATA_FILES.TABLESPACE_NAME%TYPE,
   BYTES           DBA_DATA_FILES.BYTES%TYPE,          
   BLOCKS          DBA_DATA_FILES.BLOCKS%TYPE,         
   STATUS          DBA_DATA_FILES.STATUS%TYPE,         
   RELATIVE_FNO    DBA_DATA_FILES.RELATIVE_FNO%TYPE,   
   AUTOEXTENSIBLE  DBA_DATA_FILES.AUTOEXTENSIBLE%TYPE,
   MAXBYTES        DBA_DATA_FILES.MAXBYTES%TYPE,       
   MAXBLOCKS       DBA_DATA_FILES.MAXBLOCKS%TYPE,      
   INCREMENT_BY    DBA_DATA_FILES.INCREMENT_BY%TYPE,   
   USER_BYTES      DBA_DATA_FILES.USER_BYTES%TYPE,     
   USER_BLOCKS     DBA_DATA_FILES.USER_BLOCKS%TYPE
  );  
  
  TYPE DBA_DATA_FILES_TYPE IS TABLE OF DBA_DATA_FILES_REC INDEX BY BINARY_INTEGER;

  v_dfa DBA_DATA_FILES_TYPE;
  v_idx NUMBER := 0;
  i NUMBER := 0;

  CURSOR Cc IS SELECT * FROM DBA_DATA_FILES;


BEGIN

  OPEN Cc;
  LOOP
    FETCH Cc BULK COLLECT INTO v_dfa LIMIT 100;
    EXIT WHEN Cc%NOTFOUND;
  END LOOP;

  WHILE (v_idx < 100) LOOP
    FORALL i IN v_dfa.FIRST..v_dfa.LAST
       INSERT INTO DUMMY_BB VALUES v_dfa(i);
    COMMIT;
    v_idx := v_idx + 1;
  END LOOP;

END;
/
 
       
       
       
       
SELECT EXTENTS FROM DBA_SEGMENTS WHERE SEGMENT_NAME = 'DUMMY_BB';


SELECT (BYTES / 1024) kb, (BYTES / (1024 * 1024)) mb
    FROM SYS.dba_segments
where segment_name='DUMMY_BB';




truncate table DUMMY_BB;




DBVERIFY - Verification starting : FILE = /mnt/oratest/oradata/docs_020210/contract23.dbf


DBVERIFY - Verification complete

Total Pages Examined         : 524288
Total Pages Processed (Data) : 515944
Total Pages Failing   (Data) : 0
Total Pages Processed (Index): 5088
Total Pages Failing   (Index): 0
Total Pages Processed (Other): 523
Total Pages Processed (Seg)  : 0
Total Pages Failing   (Seg)  : 0
Total Pages Empty            : 2733
Total Pages Marked Corrupt   : 0
Total Pages Influx           : 0
Highest block SCN            : 1335345274182 (310.3905412422)




drop table DUMMY_BB;
