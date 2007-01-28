package Socialtext::WikiObject::TestPlan;
use strict;
use warnings;
use base 'Socialtext::WikiObject';

=head1 NAME

Socialtext::WikiObject::TestPlan - Load wiki pages as Test plan objects

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use base 'Socialtext::WikiObject::TestPlan';
  my $test_plan = Socialtext::WikiObject::TestPlan->new(
      rester => $rester,
      page => $plan_page,
      server => $test_server,
      workspace => $test_workspace,
  );
  $test_plan->run_tests;

=head1 DESCRIPTION

Socialtext::WikiObject::TestPlan fetches Wiki pages using the Socialtext 
REST API, and parses the page into a testplan object.  This class can be
subclassed to support different types of test plans.

Test Plans look for a list item at the top level of the page looking like 
this:

  * Fixture: Foo

This tells the TestPlan object to create a Socialtext::WikiFixture::Foo
object and use it to run the tests.  A default fixture can also be specified
in the constructor.

The wiki tests are specified as tables in the top level of the page.

Test Plans can also contain links to other test plans.  If no fixture is 
found, the test plan will look for wiki links in any top level list items:

  * [This Test Plan]
  * [That Test Plan]

These pages will be loaded as TestPlan objects, and their tests will be
run as well.
 
=head1 FUNCTIONS

=head2 new( %opts )

Create a new test plan.  Options:

=over 4

=item rester

Mandatory - specifies the Socialtext::Resting object that will be used 
to load the test plan.  The rester should already have a workspace conifgured.

=item page

Mandatory - the page containing the test plan.

=item fixture_args

A hashref containing arguments to pass through to the fixture constructor.

=back

=head2 run_tests()

Execute the tests.

=cut

sub run_tests {
    my $self = shift;

    unless ($self->{table}) {
        $self->_recurse_testplans;
        return;
    }

    my $fixture_class = $self->_fixture || $self->{default_fixture};
    return unless $self->{table} and $fixture_class;

    unless ($fixture_class =~ /::/) {
        $fixture_class = "Socialtext::WikiFixture::$fixture_class";
    }

    eval "require $fixture_class";
    die "Can't load fixture $fixture_class $@\n" if $@;

    my $fix = $fixture_class->new( %{ $self->{fixture_args} } );
    $fix->run_test_table($self->{table});
}

# Find the fixture in the page
sub _fixture {
    my $self = shift;
    for (@{ $self->{items} || [] }) {
        next unless /^fixture:\s*(\S+)/i;
        return $1;
    }
    return undef;
}

sub _recurse_testplans {
    my $self = shift;

    for my $i (@{ $self->{items} }) {
        next unless $i =~ /^\[([^\]]+)\]/;
        warn "# Loading test plan $1...\n";
        my $plan = Socialtext::WikiObject::TestPlan->new(
            page => $1,
            rester => $self->{rester},
            default_fixture => $self->{default_fixture},
            fixture_args => $self->{fixture_args},
        );
        $plan->run_tests;
    }
}

1;
