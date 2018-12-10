0.

SELECT ROUND (SUM (DBMS_LOB.getlength (a.body)) / (1024 * 1024 * 1024), 2) gbytes
 FROM erp.document_file a;

    GBYTES
----------
     58.93


1.

CREATE TABLESPACE contract_lob DATAFILE 
  '/mnt/oratest/oradata/docs_020210/contract_lob01.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob02.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob03.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob04.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob05.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob06.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob07.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob08.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob09.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob10.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob11.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob12.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob13.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob14.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob15.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob16.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob17.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob18.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob19.dbf' SIZE 4096M AUTOEXTEND OFF,
  '/mnt/oratest/oradata/docs_020210/contract_lob20.dbf' SIZE 4096M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;

ALTER TABLESPACE CONTRACT_LOB ADD DATAFILE '/mnt/oratest/oradata/docs_020210/contract_lob21.dbf' SIZE 4096M AUTOEXTEND OFF;







2. обнуляем битые блобы.

update erp.document_file set body =hextoraw('DAA25889911') where document_file_s in (
 select pk from badblock_pk_tmp )

2a. проверка на бэды.




3.
-- начал в 15:10 05.02.10
ALTER TABLE ERP.document_file MOVE
TABLESPACE contract
 LOB(body) STORE AS contract_body_lob_seg0
 (TABLESPACE contract_lob);

4.


select index_name,index_type,status 
from dba_indexes 
where owner='ERP' 
 and table_name='DOCUMENT_FILE';


ALTER INDEX erp.FILEORDERNUMUNIQ REBUILD;       
ALTER INDEX erp.FILESRCUNIQ     REBUILD;        
ALTER INDEX erp.FILEUIQ         REBUILD;        
ALTER INDEX erp.XFKDOCUMENT_FILE1 REBUILD;      
ALTER INDEX erp.XFKDOCUMENT_FILE2 REBUILD;      
ALTER INDEX erp.XFKDOCUMENT_FILE3 REBUILD;      
ALTER INDEX erp.XFKDOCUMENT_FILE4 REBUILD;      
ALTER INDEX erp.XPKDOCUMENT_FILE  REBUILD;      


5.

SELECT ROUND (SUM (DBMS_LOB.getlength (a.body)) / (1024 * 1024 * 1024), 2) gbytes
 FROM erp.document_file a;





--############################################################################################################



-- тестовое таблеспасе для таблицы без блобов.
CREATE TABLESPACE test_mov DATAFILE 
'/mnt/oratest/oradata/docs_020210/test_mov01.dbf' SIZE 200M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO;



ALTER TABLE erp.stage_split_btype MOVE 
TABLESPACE test_mov;


sys@DOCS> select index_name from dba_indexes where owner='ERP' and table_name='STAGE_SPLIT_BTYPE';

INDEX_NAME
------------------------------
ALTER INDEX erp.CHECKSTAGESPLIT REBUILD;
ALTER INDEX erp.XFKSTAGE_SPLIT_BTYPE1 REBUILD;
ALTER INDEX erp.XFKSTAGE_SPLIT_BTYPE2 REBUILD;
ALTER INDEX erp.XFKSTAGE_SPLIT_BTYPE3 REBUILD;
ALTER INDEX erp.XFKSTAGE_SPLIT_BTYPE4 REBUILD;
ALTER INDEX erp.XPKSTAGE_SPLIT_BTYPE REBUILD;

