#!/usr/bin/perl -w                                                                                                                                                                                             

use strict;
use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);
use Data::Dumper;
use DBI;
use DBD::mysql;
use RRD::Simple;

my $rrd = RRD::Simple->new( file => "/home/bertinca/packets_EBDT.rrd" );
my $time = time;    # or any other epoch timestamp
my ($sec, $min, $hour, $day,$month,$year) = (localtime($time))[0,1,2,3,4,5];

my $day_db = sprintf("%02d",$day);
print "day:" . $day_db . "\n";
my $month_db = sprintf("%02d",($month+1));
print "month:" . $month_db . "\n";
my $year_db = sprintf("%02d",($year+1900));
print "year:" . $year_db . "\n";

# SQL config
my $dbase = "ogn";
my $host = "localhost";
my $user = "yourdatabasehere";
my $pw = "yourpasswordhere";
my $port = "3306";

my $connect = DBI->connect("DBI:mysql:database=$dbase;host=$host;port=$port",$user,$pw);
my $query_insert = $connect->prepare("INSERT INTO TRACKING_" . $year_db . "" . $month_db . "" . $day_db . " VALUES (null,?,?,?,?,?,?)");
my $query_create = $connect->prepare("CREATE TABLE IF NOT EXISTS TRACKING_" . $year_db . "" . $month_db . "" . $day_db . " (".
"primary_key bigint(32) NOT NULL AUTO_INCREMENT,".
"timestamp bigint(20) DEFAULT NULL,".
"id varchar(8) DEFAULT NULL,".
"longitude double DEFAULT NULL,".
"latitude double DEFAULT NULL,".
"altitude int(11) DEFAULT NULL,".
"speed int(4) DEFAULT NULL,".
"PRIMARY KEY (primary_key))");
$query_create->execute();

#10km rondom Keiheuvel
#my $is = new Ham::APRS::IS('aprs.glidernet.org:14580', 'PerlEx', 'appid' => 'your_unique_perl_app_name_here', 'filter'=>'r/+51.179/+5.222/10');

#15km rondom Diest
my $is = new Ham::APRS::IS('aprs.glidernet.org:14580', 'PerlEx', 'appid' => 'your_unique_perl_app_name_here', 'filter'=>'r/+51.004/+5.071/15');




$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

my $lastkeepalive = time();
my $packetcounter = 0;

print "connected to server aprs.glidernet.org:14580\n";

while($is->connected()) {

    # make sure we send a keep alive every 240 seconds or so                                                                                                                                                   
    my $now = time();
    if( $now - $lastkeepalive > 60 ) {
        $is->sendline('# example code');
        print "keepalive sent after $packetcounter packets\n";
        $lastkeepalive = $now;
        $rrd->update(Packets =>$packetcounter);
        $packetcounter = 0;
        $rrd->graph(
                title => "OGN packets received r15km EBDT per 60 seconds",
                sources => [ qw(Packets) ],
                #source_labels => [ ("OGN Packets EBDT per 60/sec") ],
                destination => "/var/www/html/jol/igc/rrd",
                basename => "ogn_packets_ebdt",
                periods => [ qw(hour day week month) ],
                line_thickness => 2,
                extended_legend => 1,
                width => 800,
                height => 200,
        );

    }

    # read the line from the server                                                                                                                                                                            
    my $line = $is->getline();
    next if (!defined $line);

    # parse the aprs packet                                                                                                                                                                                    
    my %packetdata;
    my $retval = parseaprs($line, \%packetdata);

    # and display it on the screen                                                                                                                                                                             
    if ($retval == 1 && substr($packetdata{comment},0,2) eq  "id") {

        my $id = substr($packetdata{comment},4,6);
        my ($sec,$min,$hour,$day,$month,$year) = (localtime($packetdata{timestamp}))[0,1,2,3,4,5];
        print "id: "."$id"." time:"."$hour:$min:$sec"." long:"."$packetdata{longitude}"." lat:"."$packetdata{latitude}"." altitude:"."$packetdata{altitude}"." speed:"."$packetdata{speed}"." comment:"."$packetdata{comment}\n";

        #print Dumper( \%packetdata );
        $packetcounter++;

        $query_insert->execute($packetdata{timestamp},substr($packetdata{comment},4,6),$packetdata{longitude},$packetdata{latitude},$packetdata{altitude},$packetdata{speed});
    }

        my $hour = (localtime)[2];
        my $minutes = (localtime)[1];
        if ($hour >= 23 && $minutes >= 59){
                print "Perl process ended 23:59\n";
                exit;
        }
}

$is->disconnect() || die "Failed to disconnect: $is->{error}";
