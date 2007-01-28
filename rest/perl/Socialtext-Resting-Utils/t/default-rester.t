#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'Socialtext::Resting::DefaultRester';
}

my $rester = Socialtext::Resting::DefaultRester->new;
isa_ok $rester, 'Socialtext::Resting';
