#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;
use DBD::mysql;
use Geo::Coordinates::DecimalDegrees;

# SQL config
my $dbase = "ogn";
my $host = "localhost";
my $user = "yourdbhere";
my $pw = "yourpasswordhere";
my $port = "3306";
my $path = "/yourpathtofolder/igc/";
my $extension = ".igc";
my $counter = 0;
my $connect = DBI->connect("DBI:mysql:database=$dbase;host=$host;port=$port",$user,$pw);
print "connection to MySQL established.\n\n";

my $now = time();
my ($S,$M,$H,$d,$m,$Y) = localtime($now);
$m += 1;
$Y += 1900;

#$Y=2017;
#$m=9;
#$d=17;

my $date = sprintf("%04d%02d%02d", $Y,$m,$d);
my $directory = $path . $Y ;

unless(-e $directory or mkdir $directory){
        die "Unable to create $directory\n";
}

$directory = $directory . "/" . $m;
unless(-e $directory or mkdir $directory){
        die "Unable to create $directory\n";
}

$directory = $directory . "/" . $d;
unless(-e $directory or mkdir $directory){
        die "Unable to create $directory\n";
}


my $query_distinct = $connect->prepare("SELECT distinct(id) FROM TRACKING_$date");
my $query_find_reg = $connect->prepare("SELECT registration FROM DDB WHERE device_id LIKE ? ");

$query_distinct->execute();

while (my $data_distinct = $query_distinct->fetchrow_hashref()) {
#print $data_distinct->{id};
        $counter++;
        my $id = $data_distinct->{id};

        my $query_select = $connect->prepare("SELECT * FROM TRACKING_$date WHERE id=\'$id\'");

        #my $registration = substr($id,2,8);
        $query_find_reg->execute($id);

        my $gevonden = 0;
        my $rego = "";
        while(my $data_reg = $query_find_reg->fetchrow_hashref()){
                $rego = $data_reg->{registration};
                print "found record in DDB: $rego matched ID: $id\n";
                $gevonden = 1;
        }

        # Use the open() function to open the file.
        my $file = "";
        if($gevonden==1){
                $file = "$directory"."/"."EBDT_" . $rego . "_" . $date .$extension;
        }
        else{
                $file = "$directory"."/"."EBDT_" . $id . "_" . $date .$extension;
        }

        unless(open FILE, '>'.$file) {
                die "Unable to create $file \n";
        }

        print "found $id ... creating file... ";
        $query_select->execute();
        my $data = $query_select->fetchrow_hashref();
        my $timestamp = $data->{timestamp};
        my ($S,$M,$H,$d,$m,$Y) = localtime($timestamp);
        $m += 1;
        $Y -= 100;
        my $dt = sprintf("%02d%02d%02d", $d,$m,$Y);

        print FILE "AXXX ogn_igc_created_file v0.2\n";
        print FILE "HFDTE".$dt."\n";
        print FILE "HFGTYGLIDERTYPE:".$id."\n";
        print FILE "HFGIDGLIDERID:".$rego."\n";
        print FILE "HFDTM100GPSDATUM:WGS-1984\n";
        print FILE "HFFTYFRTYPE:OGN File Creator by Bert Van Eyken - Diest Aero Club vzw\n";
        print FILE "HFGPSGPS:OGN\n";
        print FILE "HFPRSPRESSALTSENSOR:OGN\n";
        print FILE "HFCIDCOMPETITIONID:".$id."\n";

        # Read the matching records and print them out
        while (my $data = $query_select->fetchrow_hashref()) {
                #print B1140115249652N00212031WA0009600096027000;
                my $timestamp = $data->{timestamp};
                my ($S,$M,$H,$d,$m,$Y) = localtime($timestamp);
                my $igc_time = sprintf("%02d%02d%02d", $H,$M,$S);

                my $igc_latitude_temp = $data->{latitude};
                my $deg; my $min; my $sec;
                ($deg, $min) = decimal2dm($igc_latitude_temp);
                $min *= 1000;
                my $igc_latitude = sprintf("%02d",$deg) . sprintf("%05d",$min);
                #print "latitude: $igc_latitude_temp converted:" . sprintf("%02d",$deg) . sprintf("%05d",$min) . "\n";

                my $igc_longitude_temp = $data->{longitude};
                ($deg, $min) = decimal2dm($igc_longitude_temp);
                $min *= 1000;
                my $igc_longitude = sprintf("%03d",$deg) . sprintf("%05d",$min);
                #print "longitude: $igc_longitude_temp converted:" . sprintf("%03d",$deg) . sprintf("%05d",$min) . "\n";

                my $igc_altitude_temp = $data->{altitude};
                my $igc_altitude = sprintf("%05d",$igc_altitude_temp);

                #print "B".$igc_time." ".$igc_latitude."N ".$igc_longitude."E A ".$igc_altitude." ".$igc_altitude." 010 12 000\n";

                print FILE "B".$igc_time."".$igc_latitude."N".$igc_longitude."EA".$igc_altitude."".$igc_altitude."01012000\n";
        }

        if ($query_select->rows == 0) {
        print "No matches.\n\n";
        }
        print "file successfully saved.\n";
}
if ($query_distinct->rows == 0) {
        print "No matches on specified date.\n\n";
}
#$query_select->finish;
#$query_distinct->finish;
print "\n";
print "$counter file(s) processed.\n\n";

$connect->disconnect;
