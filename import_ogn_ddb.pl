#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;
use DBD::mysql;
use Geo::Coordinates::DecimalDegrees;

# SQL config
my $dbase = "ogn";
my $host = "localhost";
my $user = "yourdatabaseuserhere";
my $pw = "yourpasswordhere";
my $port = "3306";
my $counter = 0;
my $file = "ddb.csv";
my $connect = DBI->connect("DBI:mysql:database=$dbase;host=$host;port=$port",$user,$pw);
print "connection to MySQL established.\n\n";

my $query_drop = $connect->prepare("DROP TABLE DDB");
my $query_insert = $connect->prepare("INSERT INTO DDB VALUES (null,?,?,?,?,?,?,?)");
my $query_create = $connect->prepare("CREATE TABLE IF NOT EXISTS DDB (".
"primary_key bigint(32) NOT NULL AUTO_INCREMENT,".
"device_type varchar(1) DEFAULT NULL,".
"device_id varchar(6) DEFAULT NULL,".
"aircraft_model varchar(30) DEFAULT NULL,".
"registration varchar(10) DEFAULT NULL,".
"cn varchar(3) DEFAULT NULL,".
"tracked varchar(1) DEFAULT NULL,".
"identified varchar(1) DEFAULT NULL,".
"PRIMARY KEY (primary_key))");
$query_drop->execute();
$query_create->execute();

system("wget http://ddb.glidernet.org/download -O ddb.csv");
if ( $? == -1 )
{
   print "download failed: $!\n";
}
else
{
   printf "download exited with value %d\n\n", $? >> 8;
}


unless(open FILE, $file) {
        die "Unable to open $file \n";
}

print "Opened file $file.. reading records...\n";


while (my $line = <FILE>){
        if($counter>0){
                #print $line;
                my @values = split(",",$line);

                my $device_type = "$values[0]";
                $device_type =~ tr/\'//d;
                #print "$device_type\n";

                my $device_id = "$values[1]";
                $device_id =~ tr/\'//d;
                #print "$device_id\n";

                my $aircraft_model = "$values[2]";
                $aircraft_model =~ tr/\'//d;
                #print "$aircraft_model\n";

                my $registration = "$values[3]";
                $registration =~ tr/\'//d;
                #print "$registration\n";

                my $cn = "$values[4]";
                $cn =~ tr/\'//d;
                #print "$cn\n";

                my $tracked = "$values[5]";
                $tracked =~ tr/\'//d;
                #print "$tracked\n";

                my $identified = "$values[6]";
                $identified =~ tr/\'//d;
                #print "$identified\n";

                $query_insert->execute("$device_type", "$device_id", "$aircraft_model", "$registration", "$cn", "$tracked", "$identified");

                STDOUT->autoflush(1);
                print ".";
                if($counter % 40  == 0){
                        print "\n";
                }
        }
        $counter += 1;
}
close(FILE);

if($counter == 0) {
        print "No lines processed.\n\n";
}
#$query_select->finish;
#$query_distinct->finish;
print "\n";
print "$counter line(s) processed.\n\n";

$connect->disconnect;
