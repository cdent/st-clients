package Socialtext::Resting::Getopt;
use strict;
use warnings;
use base 'Exporter';
use Socialtext::Resting::DefaultRester;
use Getopt::Long qw/:config pass_through/;
our @EXPORT_OK = qw/get_rester/;

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
    my %opts;
    GetOptions(
        \%opts,
        'server=s',
        'workspace=s',
        'username=s',
        'password=s',
        'rester-config=s',
    );
    return Socialtext::Resting::DefaultRester->new(%opts);
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
