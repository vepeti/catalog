#!/usr/bin/perl

use warnings;
use strict;
use Time::Local;
use Getopt::Long;

#
# Subroutines
#

sub helpmsg()
{
print "
Usage: $0 [OPTIONS]
Example: $0 -f '2017 08 12 09:35:57' -l '/var/log/apache2/access.log'

-c, --config	Use config file instead params
-f, --from	Set From date
-t, --to	Set To date (default is current time)
-l, --log	Set log file
-o, --out	Print lines into file
-h, --help	Print this help
";
exit;
}

# ini file read subrutine
sub read_config
{
    my %hash;
    my $paramcount=@_;
    if ($paramcount>1)
    {
        print "Too many params!";
        return 0;
    }
    elsif ($paramcount<1)
    {
        print "Missing parameter!";
        return 0;
    }
    elsif (! -r $_[0])
    {
        print "Can not open config file!\n";
        return 0;
    }

    open(my $file, $_[0]);
    while (<$file>)
    {
        if ($_!~/^(#|;|$)/)
        {
            chomp($_);
            my ($key,$value)=((split /=/, $_)[0],(split /=/, $_)[1]);
            $hash{$key}=$value;
        }
    }
    close($file);
    return %hash;
}


#
# Begin
#

# collect params with getopt or config file

if (!@ARGV)
{
    &helpmsg;
}

my %conf;
my $config;

GetOptions(
    "c|config=s"=> \$config,
    "h|help"	=> \$conf{"help"},
    "f|from=s"	=> \$conf{"from"},
    "t|to=s"	=> \$conf{"to"},
    "l|log=s"	=> \$conf{"log"},
    "o|out=s"	=> \$conf{"out"}
);

if ($config)
{
    if (&read_config($config))
    {
	%conf=&read_config($config);
    }
}

if ($conf{"help"})
{
    &helpmsg;
}

if ((!$conf{"from"}) || (!$conf{"log"}))
{
    print "Missing parameters!\n";
    exit;
}

if (!$conf{"to"})
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $year+=1900;
    $mon+=1;
    $sec=~s/^(\d)$/0$1/;
    $min=~s/^(\d)$/0$1/;
    $hour=~s/^(\d)$/0$1/;
    $mon=~s/^(\d)$/0$1/;
    $mday=~s/^(\d)$/0$1/;
    $conf{"to"}="$year $mon $mday $hour:$min:$sec";
}

# Init variables
my %from;
my %to;
my $log_regex;
my $newlog;

my $from_stamp;
my $to_stamp;

# check the given param format
if ((!exists($conf{"from"})) || ($conf{"from"}!~/^(20[0-9]{2}) (0[1-9]|1[0-2]) (0[1-9]|[1-2][0-9]|3[0-1]) (0[0-9]|1[0-9]|2[0-3]):(0[0-9]|[1-5][0-9]):(0[0-9]|[1-5][0-9])$/))
{
    print "Invalid from date! Exiting...\n";
    exit;
}
else
{
    $from{"year"}=$1;
    $from{"month"}=$2;
    $from{"day"}=$3;
    $from{"hour"}=$4;
    $from{"min"}=$5;
    $from{"sec"}=$6;
}

if ((!exists($conf{"to"})) || ($conf{"to"}!~/^(20[0-9]{2}) (0[1-9]|1[0-2]) (0[1-9]|[1-2][0-9]|3[0-1]) (0[0-9]|1[0-9]|2[0-3]):(0[0-9]|[1-5][0-9]):(0[0-9]|[1-5][0-9])$/))
{
    print "Invalid end date! Exiting...\n";
    exit;
}
else
{
    $to{"year"}=$1;
    $to{"month"}=$2;
    $to{"day"}=$3;
    $to{"hour"}=$4;
    $to{"min"}=$5;
    $to{"sec"}=$6;
}

# init months hash
my %mons = (
'Jan' => 1,
'Feb' => 2,
'Mar' => 3,
'Apr' => 4,
'May' => 5,
'Jun' => 6,
'Jul' => 7,
'Aug' => 8,
'Sep' => 9,
'Oct' => 10,
'Nov' => 11,
'Dec' => 12,
);

# calc the from and end date parse and check
$from_stamp=timelocal($from{"sec"},$from{"min"},$from{"hour"},$from{"day"},$from{"month"}-1,$from{"year"})."\n";
$to_stamp=timelocal($to{"sec"},$to{"min"},$to{"hour"},$to{"day"},$to{"month"}-1,$to{"year"})."\n";

if ($from_stamp>$to_stamp)
{
    print "The end date earlier, than the from date! Exiting...\n";
    exit;
}

if ((!exists($conf{"log"})) || (! -e $conf{"log"}))
{
    print "No log file found! Exiting...\n";
    exit;
}

# confirmation on large log files
my $size=int((-s $conf{"log"})/1048576);

if ($size>1000)
{
    print "The selected log file's size is: $size MB. Are you sure? [y/n]\n";
    my $answer=<STDIN>;
    chomp($answer);
    if ($answer ne "y")
    {
        exit;
    }
}

if ($conf{"out"})
{
    open($newlog, '>', $conf{"out"}) or die("Unable to open file: $conf{'out'}");
}

my $counter=0;

my $file;

if ($conf{"log"}=~/.gz$/)
{
open($file, "gunzip -c ".$conf{"log"}." |") || die("can't open pipe to $file");
}
else
{
open($file, $conf{"log"}) or die("Unable to open file:  $conf{'log'}");
}

# automatic choose the log format, based on the first line
while (<$file>)
{
# [Oct Tue 8 12:30:56
    if ($_=~/\[\w{3} (\w{3}) (\d{1,2}) (\d{2}):(\d{2}):(\d{2})/)
        {
            $log_regex='\[\w{3} (\w{3}) (\d{1,2}) (\d{2}):(\d{2}):(\d{2})';
            $conf{"log_format"}=1;
            last;
        }
# [2017-10-28 12:36:58] or 2017-10-28 12:36:58
    elsif ($_=~/\[?(20\d\d)-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\]?/)
        {
    $log_regex='\[?(20\d\d)-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\]?';
            $conf{"log_format"}=2;
            last;
        }
# [03/Nov/2017:06:32:46 +
    elsif ($_=~/\[(\d{2})\/(\w{3})\/(20\d\d):(\d{2}):(\d{2}):(\d{2}) \+/)
        {
	    $log_regex='\[(\d{2})\/(\w{3})\/(20\d\d):(\d{2}):(\d{2}):(\d{2}) \+';
            $conf{"log_format"}=3;
            last;
        }
# [Tue Sep  5 14:00:06 2017]
    elsif ($_=~/\[\w{3} (\w{3}) {1,2}(\d{1,2}) (\d{2}):(\d{2}):(\d{2}) (\d{4})/)
            {
            $log_regex='\[\w{3} {1,2}(\w{3}) (\d{1,2}) (\d{2}):(\d{2}):(\d{2}) (\d{4})';
            $conf{"log_format"}=4;
            last;
        }
# Oct 29 06:39:01
    else
        {
            $log_regex='^(\w{3}) {1,2}(\d{1,2}) (\d{2}):(\d{2}):(\d{2})';
            $conf{"log_format"}=0;
            last;
        }
}

# turn off buffer
$|=1;

my $day;
my $hour;
my $min;
my $sec;
my $year=$from{"year"};

# the main process, export the lines
while (<$file>)
{
    if ($_=~/$log_regex/)
    {
        my $month;

        if ($conf{"log_format"}==2)
        {
            $year=$1;
	    $month=$2-1;
	    $day=$3;
	    $hour=$4;
	    $min=$5;
	    $sec=$6;
        }
        elsif ($conf{"log_format"}==3)
        {
            $day=$1;
	    $month=$mons{$2}-1;
	    $year=$3;
            $hour=$4;
            $min=$5; 
            $sec=$6;
        }
        elsif ($conf{"log_format"}==4)
        {
            $day=$2;
            $month=$mons{$1}-1;
            $year=$6;
            $hour=$3;
            $min=$4;
            $sec=$5;
        }
        else
        {
	    $month=$mons{$1}-1;
            $day=$2;
            $hour=$3;
            $min=$4;
            $sec=$5;
        }

        my $log_stamp=timelocal($sec,$min,$hour,$day,$month,$year);

        if (($log_stamp>=$from_stamp) && ($log_stamp<=$to_stamp))
        {
            if ($conf{"out"})
            {
        print $newlog $_;
        $counter++;
            }
            else
            {
        print $_;
            }
        }
    }
    if ($conf{"out"})
    {
        print "\r".$.." line is processed... ".$counter." line is listed";
    }
}
close($file);

print "Done!\n";

if ($conf{"out"})
{
    close($newlog);
    print "\n";
}

exit 1;
