#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

my $igc_to_kml_path = "http://cunimb.net/igc2map.php?color=red&width=2&alti=pres&link=";

my $path = "/yourpathtofolder/igc/";
my $now = time();
my ($S,$M,$H,$d,$m,$Y) = localtime($now);
$m += 1;
#$d = 17;
$Y += 1900;
my $date = sprintf("%04d%02d%02d", $Y,$m,$d);

#$Y=2017;
#$m=9;
#$d=19;

my $directory = $path . $Y . "/" . $m . "/" . $d . "/";
my $filename = $directory . "index.html";
my $igc_file_path = "http:/yoururltofolder/igc/" . $Y . "/" . $m . "/" . $d . "/";

open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
print "directory = $directory\n";
print "filename = $filename\n";

opendir (DIR, $directory) or die $!;
print $fh "<head><title>report flights on $d $m $Y</title></head>\n";
print $fh "<body><table cellspacing='3' cellpadding='3'>\n";
print $fh "<tr><td colspan='5' align='center'><b>logged flights within 15km radius EBDT on $d/$m/$Y</b><br><br></td></tr>\n";

my $counter = 1;
my $alternate = 0;

while (my $file = readdir(DIR)) {
        next if ($file =~ m/^\./);
        next if ($file =~ "index.html");
        print "$file\n";
        if($alternate == 0){
                print $fh "<tr bgcolor=\#D0D0D0>\n";
                $alternate = 1;
        }
        else{
                print $fh "<tr>\n";
                $alternate = 0;
        }

        my $filesize = -s "$directory/$file";
        $filesize = ceil($filesize/1024);

        print $fh "<td align='center'>$counter</td>";
        print $fh "<td>$file</td>";
        print $fh "<td align='right'>$filesize kb</td>";
        print $fh "<td align='center'><a href='" . $igc_file_path . $file . "'> download </td>\n";
        print $fh "<td align='center'><a target=new href='" . $igc_to_kml_path  . $igc_file_path . $file . "'> view </td>\n";
        print $fh "</tr>\n";
        $counter++;
}

print $fh "</table></body>\n";

close $fh;
closedir(DIR);
exit 0;
