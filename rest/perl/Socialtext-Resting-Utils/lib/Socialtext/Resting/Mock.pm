package Socialtext::Resting::Mock;
use strict;
use warnings;

=head1 NAME

Socialtext::Resting::Mock - Fake rester

=head1 SYNOPSIS

  my $rester = Socialtext::Resting::Mock->(file => 'foo');

  # returns content of 'foo'
  $rester->get_page('bar');

=cut

our $VERSION = '0.02';

=head1 FUNCTIONS

=head2 new( %opts )

Create a new fake rester object.  Options:

=over 4

=item file

File to return the contents of.

=back

=cut

sub new {
    my ($class, %opts) = @_;
    if ($opts{file}) {
        die "not a file: $opts{file}" unless -f $opts{file};
    }
    my $self = \%opts;
    bless $self, $class;
    return $self;
}

=head2 get_page( $page_name )

Returns the content of the specified file or the page stored 
locally in the object.

=cut

sub get_page {
    my $self = shift;
    my $page_name = shift;

    if ($self->{file}) {
        warn "Mock rester: returning content of $self->{file} for page ($page_name)\n";
        open(my $fh, $self->{file}) or die "Can't open $self->{file}: $!";
        local $/;
        my $page = <$fh>;
        close $fh;
        return $page;
    }
    return shift @{ $self->{page}{$page_name} };
}

=head2 put_page( $page_name )

Stores the page content in the object.

=cut

sub put_page {
    my ($self, $page, $content) = @_;
    die delete $self->{die_on_put} if $self->{die_on_put};
    push @{ $self->{page}{$page} }, $content;
}

=head2 put_pagetag( $page, $tag )

Stores the page tags in the object.

=cut

sub put_pagetag {
    my ($self, $page, $tag) = @_;
    push @{$self->{page_tags}{$page}}, $tag;
}

=head2 get_pagetags( $page )

Retrieves page tags stored in the object.

=cut

sub get_pagetags {
    my ($self, $page) = @_;
    return delete $self->{page_tags}{$page};
}

=head2 die_on_put( $rc )

Tells the next put_page() to die with the supplied return code.

=cut

sub die_on_put {
    my $self = shift;
    my $rc = shift;

    $self->{die_on_put} = $rc;
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
1;
