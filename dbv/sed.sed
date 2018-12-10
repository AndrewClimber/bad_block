sed 's/DBV-00200: Block, dba//

cat nohup.out | sed 's/DBV-00200: Block, dba//' | sed 's/, already marked corrupted//' > bad_blk.txt
 