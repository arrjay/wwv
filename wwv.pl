#!/usr/bin/env perl
use warnings;
use strict;
use JSON -support_by_pp;
use POSIX;
use DateTime;
use Digest::SHA;

# get your file hash
my $sha1 = Digest::SHA -> new(1);
$sha1->add(__FILE__);

# get the time from datetime...
# NOTE: should be UTC ;)
my $dt = DateTime -> now();

# and JSON-ify it.
my %blobtime;
$blobtime{'GENERATOR'} = $sha1->hexdigest;
# yeaaaah this is hardcoded.
$blobtime{'CALENDAR'} = "Gregorian";
$blobtime{'MONTH'} = $dt->month();
$blobtime{'EN'}{'MONTH_NAME'} = $dt->month_name();
$blobtime{'EN'}{'MONTH_ABBR'} = $dt->month_abbr();
$blobtime{'EN'}{'WDAY_NAME'} = $dt->day_name();
$blobtime{'EN'}{'WDAY_ABBR'} = $dt->day_abbr();
$blobtime{'DAY'} = $dt->day();
$blobtime{'YEAR'} = $dt->year();
$blobtime{'TZ'}{'LONG_NAME'} = $dt->time_zone()->name;
$blobtime{'TZ'}{'SHORT_NAME'} = $dt->time_zone_short_name();
$blobtime{'WDAY'} = $dt->day_of_week();
$blobtime{'YDAY'} = $dt->day_of_year();
$blobtime{'HOUR'} = $dt->hour();
$blobtime{'MINUTE'} = $dt->minute();
$blobtime{'SECOND'} = $dt->second();
$blobtime{'WEEK'}{'NUMBER'} = $dt->week_number();
$blobtime{'WEEK'}{'YEAR_OF'} = $dt->week_year();
$blobtime{'OFFSET'} = $dt->offset();
$blobtime{'EPOCH'} = $dt->epoch();
$blobtime{'LEAP_SECONDS'} = $dt->leap_seconds();

# JSON's truth values require special constants.
if ($dt->is_dst()) {
  $blobtime{'IS_DST'} = JSON::true;
} else {
  $blobtime{'IS_DST'} = JSON::false;
}

my $bt_ref = \%blobtime;
my $output = to_json( $bt_ref, { utf8 => 1, pretty => 1 } ) ;
print $output;
