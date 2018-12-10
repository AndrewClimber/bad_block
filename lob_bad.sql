set serverout on
		exec dbms_output.enable(100000);
		declare
		 error_1578 exception;
		 pragma exception_init(error_1578,-1578);
		 n number;
		 cnt number:=0;
		 badcnt number:=0;
		begin
		  for cursor_lob in
		        (select rowid r, &LOB_COLUMN_NAME L from &OWNER..&TABLE_NAME)
		  loop
		    begin
		      n:=dbms_lob.instr(cursor_lob.L,hextoraw('AA25889911'),1,999999) ;
		    exception
		     when error_1578 then
		       dbms_output.put_line('Got ORA-1578 reading LOB at '||cursor_lob.R);
		       badcnt:=badcnt+1;
		    end;
		    cnt:=cnt+1;
		  end loop;
		  dbms_output.put_line('Scanned '||cnt||' rows - saw '||badcnt||' errors');
		end;
		/




create table bad_lobs (