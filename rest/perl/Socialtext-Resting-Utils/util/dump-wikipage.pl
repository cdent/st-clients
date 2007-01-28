#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Socialtext::Resting;
use Socialtext::WikiObject;
use lib 'lib';

my $rester = Socialtext::Resting->new(
    username => 'devnull1@socialtext.com',
    password => 'd3vnu11l',
    server => 'http://localhost:21000/',
    workspace => 'admin',
);

my $o = Socialtext::WikiObject->new(rester => $rester, page => shift);
print Dumper $o;
