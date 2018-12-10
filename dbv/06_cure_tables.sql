1.
select segment_name, segment_type, owner
from dba_extents
where file_id = 28
and 329391 between block_id
and block_id + blocks -1;


2.
connect под erp 
