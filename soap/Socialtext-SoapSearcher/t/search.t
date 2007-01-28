#!perl
#

use strict;
use warnings;
use Readonly;
use Test::More;

BEGIN {
    use_ok "Socialtext::SoapSearcher";
}

Readonly my $USERNAME   => 'soap.test@socialtext.com';
Readonly my $PASSWORD   => 'bubbles';
Readonly my $DESTINATIONS => [
    ['www2.socialtext.net' => 'corp'],
    ['www2.socialtext.net' => 'st-soap-test'],
    ['www.socialtext.net'  => 'st-soap-test'],
    ];

plan tests => 5;

ONE_WORKSPACE: {
    my $searcher = Socialtext::SoapSearcher->new(
        username => $USERNAME,
        password => $PASSWORD,
        destinations => [$DESTINATIONS->[0]],
    );

    my $results = $searcher->query('hacktivation');

    like $results->[0]->{subject}, qr/mml work log/,
        'a search for hacktivation gets mml log';
}

# XXX: this doesn't actually do a very good job of testing
MULTI_WORKSPACE: {
    my $searcher = Socialtext::SoapSearcher->new(
        username   => $USERNAME,
        password   => $PASSWORD,
        destinations => [$DESTINATIONS->[0], $DESTINATIONS->[1]],
    );

    my $results = $searcher->query('tensegrity');

    ok $results->[0]->{subject}, 'a search for tensegrity gets a page with a subject';
    ok $results->[0]->{revisions}, 'a search for tensegrity gets a page at least one revision';
}


MULTI_SERVER: {
    my $searcher = Socialtext::SoapSearcher->new(
        username     => $USERNAME,
        password     => $PASSWORD,
        #destinations =>
        #    [ $DESTINATIONS->[0], $DESTINATIONS->[1], $DESTINATIONS->[2] ],
        destinations => [ $DESTINATIONS->[2] ],
    );

    my $results = $searcher->query('tensegrity OR hactivation OR cows');

    ok $results->[0]->{subject}, 'a search for tensegrity gets a page with a subject';
    ok $results->[0]->{revisions}, 'a search for tensegrity gets a page at least one revision';
}
