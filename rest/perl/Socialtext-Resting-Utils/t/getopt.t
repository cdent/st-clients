#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 32;

BEGIN {
    use_ok 'Socialtext::Resting::Getopt', 'get_rester';
}

No_args: {
    run_ok('');
}

App_args: {
    run_ok("--monkey", Monkey => 1);
    run_ok("foo bar", ARGV => 'foo bar');
}

Rester_options: {
    run_ok("--server foo", server => 'foo');
    run_ok("--workspace monkey", workspace => 'monkey');
}

sub run_ok {
    my $args = shift;
    my %args = (
        username  => 'user-name',
        password  => 'pass-word',
        workspace => 'work-space',
        server    => 'http://socialtext.net',
        monkey    => '',
        ARGV      => '',
        @_,
    );
    my @tests = @_;

    my $prog = "$^X t/getopt-test.pl --rester-config=t/rester.conf";
    my $output = qx($prog $args 2>&1);
    for my $f (keys %args) {
        like $output, qr/$f=$args{$f}/i;
    }
}

1;
