select e.tablespace_name,e.owner,e.segment_name,e.segment_type,c.block#--,e.block_id
    from dba_extents e,  --v$database_block_corruption c 
     v$backup_corruption c
    where --c.file# in (37,38) and
    (e.file_id=c.file# and c.block# between e.block_id and e.block_id+e.blocks-1)
    or
    (e.file_id=c.file# and c.block#+c.blocks-1 between e.block_id and e.block_id+e.blocks-1);






 select segment_name, segment_type, owner
       from dba_extents
      where file_id = 20
        and 87958 between block_id
            and block_id + blocks -1;