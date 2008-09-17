#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;
use Socialtext::WikiFixture::TestUtils qw/fixture_ok/;
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
    like $@, qr/Bad command/;
}

Page_including: {
    $rester->put_page('Foo', "| comment | included |\n");
    $rester->put_page('Foo', "| comment | included |\n");
    $rester->put_page('Foo', "| comment | included |\n");
    $rester->put_page('Bar', "| include | Baz |\n");
    $rester->put_page('Baz', "| comment | included2 |\n");
    $rester->put_page('Test Plan', <<EOT);
* Fixture: Null
| include | Foo |
| include | Foo |
| include | Foo |
| include | Bar |
EOT
    my $plan = Socialtext::WikiObject::TestPlan->new(
        rester => $rester,
        page => 'Test Plan',
    );

    $plan->run_tests;
    is $plan->{fixture}{calls}{include}, 5;
    is $plan->{fixture}{calls}{comment}, 4;
}

Special_functions: {
    no warnings qw/redefine once/;
    my $f = Socialtext::WikiFixture->new;
    my $diag = '';
    *Socialtext::WikiFixture::diag = sub { $diag .= "$_[0]\n" };

    Comment: {
        $f->comment('foo');
        is $diag, "\ncomment: foo\n";
    }

    Set: {
        $diag = '';
        $f->set('foo', 'bar');
        is $diag, "Set 'foo' to 'bar'\n";
        is $f->{foo}, 'bar';
    }

    Using_a_variable: {
        $diag = '';
        $rester->put_page('Test Plan', <<'EOT');
* Fixture: Socialtext::WikiFixture
| set | mom | linda |
| comment | Hi, %%mom%% |
EOT
        my $plan = Socialtext::WikiObject::TestPlan->new(
            rester => $rester,
            page => 'Test Plan',
        );
        $plan->run_tests;
        like $diag, qr/comment: Hi, linda/;
    }

    Using_missing_variable: {
        $rester->put_page('Test Plan', <<'EOT');
* Fixture: Socialtext::WikiFixture
| comment | Hi, %%mom%% |
EOT
        my $plan = Socialtext::WikiObject::TestPlan->new(
            rester => $rester,
            page => 'Test Plan',
        );
        eval { $plan->run_tests };
        like $@, qr/Undef var - 'mom'/;
    }

    Set_default: {
        $diag = '';
        $f->set_default('poop', 'bar');
        is $diag, "Set 'poop' to 'bar'\n";
        is $f->{poop}, 'bar';

        $diag = '';
        $f->set_default('poop', 'baz');
        is $diag, '';
        is $f->{poop}, 'bar';

        $diag = '';
        $f->set('poop', 'baz');
        is $diag, "Set 'poop' to 'baz'\n";
        is $f->{poop}, 'baz';
    }

    Bad_set: {
        $diag = '';
        $f->set('bar');
        like $diag, qr/Both name and value/;
        is $f->{bar}, undef;;

        $diag = '';
        $f->set(undef, 'bar');
        like $diag, qr/Both name and value/;
    }
}


Escaping_options: {
    my @testcases = (
        [ '`foo`'   => 'foo' ],
        [ '\`foo\`' => '`foo`' ],
    );

    for my $t (@testcases) {
        $rester->put_page('Foo', <<EOT);
* Fixture: Null
| comment | $t->[0] |
EOT
        my $plan = Socialtext::WikiObject::TestPlan->new(
            rester => $rester,
            page => 'Foo',
        );

        $plan->run_tests;
        is_deeply $plan->{fixture}{args}{comment}, [[$t->[1]]];
        is $plan->{fixture}{calls}{comment}, 1;
    }
}
