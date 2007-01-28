package Socialtext::Resting::DefaultRester;
use strict;
use warnings;
use Socialtext::Resting;

=head1 NAME

Socialtext::Resting::DefaultRester - load a rester from a config file.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Load server, workspace and username from a file, so you don't need to
specify that for every program using Socialtext::Resting.

    use Socialtext::Resting::DefaultRester;

    my $rester = Socialtext::Resting::DefaultRester->new;
    print $rester->get_page('Foo');

=head1 FUNCTIONS

=head2 new

Create a new Default Rester by using values from ~/.wikeditrc.

The config file is expected to be in the following format:

  server = your-server
  workspace = some-workspace
  username = your-user
  password = your-password

=cut

our $CONFIG_FILE = "$ENV{HOME}/.wikeditrc";

sub new {
    my $class = shift;
    my %args = (@_);
    for my $k (keys %args) {
        delete $args{$k} unless defined $args{$k};
    }

    my %opts = (
        _load_config($CONFIG_FILE),
        %args,
    );
    return Socialtext::Resting->new(%opts);
}

sub _load_config {
    my $file = shift;

    my %opts;
    if (-e $file) {
        open(my $fh, $file) or die "Can't open $file: $!";
        while(<$fh>) {
            if (/^(\w+)\s*=\s*(\S+)\s*$/) {
                $opts{$1} = $2;
            }
        }
        close $fh;
    }
    return %opts;
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-default-rester at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Socialtext::Resting::DefaultRester

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Socialtext-Resting-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Socialtext-Resting-Utils>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Socialtext-Resting-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Socialtext-Resting-Utils>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
