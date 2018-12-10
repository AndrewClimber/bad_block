select 'nohup dbv blocksize=8192 file='||name||' logfile='||name||'.log &'
from v$datafile;