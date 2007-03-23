package Socialtext::Resting::Getopt;
use strict;
use warnings;
use base 'Exporter';
use Socialtext::Resting::DefaultRester;
use Getopt::Long qw/:config/;
our @EXPORT_OK = qw/get_rester rester_usage/;

=head1 NAME

Socialtext::Resting::Getopt - Handle command line rester args

=head1 SYNOPSIS

  use Socialtext::Resting::Getopt qw/get_rester/;
  my $rester = get_rester();

=cut

our $VERSION = '0.01';

=head1 FUNCTIONS

=head2 get_rester

Create a new rester from command line args.

=cut

sub get_rester {
    my %opts = @_;
    Getopt::Long::Configure('pass_through');
    GetOptions(
        \%opts,
        'server=s',
        'workspace=s',
        'username=s',
        'password=s',
        'rester-config=s',
    );
    Getopt::Long::Configure('no_pass_through');
    return Socialtext::Resting::DefaultRester->new(%opts);
}

=head2 rester_usage

Return usage text for the arguments accepted by this module.

=cut

sub rester_usage {
    my $rc_file = $Socialtext::Resting::DefaultRester::CONFIG_FILE;
    return <<EOT;
REST API Options:
 --server      Socialtext server to archive mail to
 --username    User to login as
 --password    User password
 --workspace   Workspace to archive mail to
 --rester-config   Config file containing 'key = value'

Rester Config:
Put the above options into $rc_file like this:

  username = some_user\@foobar.com
  password = your_pass
  workpace = your_workspace
  server   = https://www.socialtext.net/
EOT
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
