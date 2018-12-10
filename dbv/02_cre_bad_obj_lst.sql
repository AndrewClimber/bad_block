declare
 fil# number;
 blk# number;
 seg  varchar2(50);
 typ  varchar2(50);
 own  varchar2(50);
 tbs  varchar2(50);
begin
  for Cc in ( select bb from badblock_list_tmp ) loop
    fil# := dbms_utility.data_block_address_file(Cc.bb);
    blk# := dbms_utility.data_block_address_block(Cc.bb);
    begin
/*      select owner,segment_name,segment_type,tablespace_name into own,seg,typ,tbs 
      from dba_extents where file_id=fil# and blk# between block_id and block_id+blocks-1;
*/
      insert into bad_obj_list values(blk#,fil#,null,null,null,null);
    exception 
      when NO_DATA_FOUND then
       insert into bad_free_list values(blk#,fil#,null);
       commit;
    end;    
  end loop;
  commit;
end;


select 'bad_obj_list= ', count(*) from bad_obj_list
union all
select 'bad_free_list= ', count(*) from bad_free_list