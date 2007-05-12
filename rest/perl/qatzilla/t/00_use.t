#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);

use FindBin;
use lib 'lib';
use lib "$FindBin::Bin/lib";

$ENV{QATZILLA_CONFIG} = 't/etc/qatzilla.conf';

my @libs = grep { s#(^lib/|\.pm$)##g and s#/#::#g }
           glob 'lib/Sophos/Qatzilla/*.pm';
foreach my $lib (@libs) {
    use_ok($lib);
}
