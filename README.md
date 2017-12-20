# NAME
- catalog - collate lines from any log file between 2 timestamps

# SYNOPSIS
- Usage: catalog.pl [options]

# EXAMPLE
- catalog.pl -f '2017 08 12 09:35:57' -l '/var/log/apache2/access.log'  
- catalog.pl -f '2017 12 30 19:35:57' -t '2017 12 31 23:59:59' -l '/var/log/apache2/access.log' -o 'mylog.txt'  
- catalog.pl -c /root/catalog.conf

# DESCRIPTION
    Catalog selects lines from any log files, within 2 date you given.
    The program detects the date format in log file automatically.
    Log file can be simple log file or gzip file. You can use config
    file or stdin to add parameters. The program returns the lines
    to stdout or specific file. The .deb file includes the main program
    and  make a simple config file to /etc/catalog.

# OPTIONS
-c, --config    Use config file instead params  
-f, --from      Set From date  
-t, --to        Set To date (default is current time)  
-l, --log       Set log file  
-o, --out       Print lines into file  
-h, --help      Print this help  
