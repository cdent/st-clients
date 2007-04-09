#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;
use lib 't/lib';
use Test::WWW::Selenium qw/$SEL/; # mocked

BEGIN {
    use lib 'lib';
    use_ok 'Socialtext::WikiObject::TestPlan';
}

my $rester = Socialtext::Resting::Mock->new;

Base_fixture: {
    $rester->put_page('Test Plan', <<EOT);
* Fixture: Socialtext::WikiFixture
| foo |
EOT
    my $plan = Socialtext::WikiObject::TestPlan->new(
        rester => $rester,
        page => 'Test Plan',
    );

    eval { $plan->run_tests };
    ok $@;
}

