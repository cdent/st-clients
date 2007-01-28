package t::FixtureUtils;
use strict;
use warnings;
use base 'Exporter';
use Test::More;
use lib 't/lib';
use Mock::Rester; # mocked
use Test::WWW::Selenium qw/$SEL/; # mocked

our @EXPORT_OK = qw/fixture_ok/;

# Add to t/bin to the path for our fake st-* commands
$ENV{PATH} = "t/bin:$ENV{PATH}";

my $rester = Mock::Rester->new;

sub fixture_ok {
    my %args = @_;

    ok 1, $args{name};

    $rester->put_page('Test Plan', $args{plan});
    my $plan = Socialtext::WikiObject::TestPlan->new(
        rester => $rester,
        page => 'Test Plan',
        default_fixture => $args{default_fixture},
        fixture_args => {
            host => 'selenium-server',
            username => 'testuser',
            password => 'password',
            browser_url => 'http://server',
            workspace => 'foo',
            %{ $args{fixture_args} || {} },
        },
    );

    if ($args{sel_setup}) {
        for my $s (@{$args{sel_setup}}) {
            $SEL->set_return_value(@$s);
        }
    }

    $plan->run_tests;

    for my $t (@{$args{tests}}) {
        $SEL->method_args_ok(@$t);
    }

    $SEL->method_args_ok('stop', undef);
    $SEL->empty_ok($args{extra_calls_ok});
}

1;
