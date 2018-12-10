options__
 delimiter==>';'
__end


prolog__
 set autocommit 100
 spool bad_block_list.log
__end


repeat__
INSERT INTO badblock_list_tmp VALUES(#3);
__end


epilog__
 spool off
__end
