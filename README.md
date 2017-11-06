# NAME
- catalog - collate lines from any log file between 2 timestamps

# SYNOPSIS
- Usage: catalog.pl [options]

# DESCRIPTION
    Catalog selects lines from any log files, within 2 date you given.
    The program detects the date format in log file automatically.
    Log file can be simple log file or gzip file. You can use config
    file or stdin to add parameters. The program returns the lines
    to stdout or specific file. The .deb file includes the main program
    and  make a simple config file to /etc/catalog.

# OPTIONS
    -c <FILE>	: use config file instead STDIN
    -f <FILE>	: print output to specific file
    -h		: print help
