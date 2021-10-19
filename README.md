# OGN
Quick and dirty script for OGN logging purposes written somewhere between 2015-2017.

All scripts run on our club server in Azure (it is alse there for webhosting and other purposes) but can run on any kind of machine.

The scripts are to be added to a cronjob.
- ogn_ebdt.pl runs eternally and logs all OGN data in a MySQL database in a given range. (keep the radius small to leave only a small footprint on the APRS servers)
- import_ogn_ddb.pl once a week, it imports the OGN DB in a local database
- create_igc.pl and create_html.pl every day hourly between 1800 and 2300, the first creates the IGC files, the second the index.html files.

Several open issues still stand:
- UTC should be used instead of local time
- Clean up routine database
- rethink the whole code because it is a mess, but hey, it works :-)

Several perl modules are needed, these are the verions I use.
- Date-Calc-6.4
- DBI-1.633
- Geo-Coordinates-DecimalDegrees-0.09
- GIS-Distance-0.08
- Ham-APRS-FAP-1.20
