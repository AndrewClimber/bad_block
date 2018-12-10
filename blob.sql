SELECT ROUND (SUM (DBMS_LOB.getlength (a.body)) / (1024 * 1024 * 1024), 2) gbytes
 FROM erp.document_file a;
