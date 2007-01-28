#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use lib 't/lib';
use Mock::Rester; # mocked
use Test::WWW::Selenium qw/$SEL/; # mocked

BEGIN {
    use lib 'lib';
    use_ok 'Socialtext::WikiObject::TestPlan';
}

my $rester = Mock::Rester->new;

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

