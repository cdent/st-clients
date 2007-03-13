package Socialtext::EditBlog;
use warnings;
use strict;
use base 'Socialtext::EditPage';

=head1 NAME

Socialtext::EditBlog - Edit a wiki page using your favourite EDITOR.

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Fetch a page, edit it, and then post it.

    use Socialtext::EditBlog;

    # The rester is set with the server and workspace
    my $rester = Socialtext::Resting->new(%opts);

    my $s = Socialtext::EditBlog->new(rester => $rester);
    $s->new_post();

=head1 FUNCTIONS

=head2 new( %opts )

Arguments:

=over 4

=item rester

Users must provide a Socialtext::Resting object setup to use the desired 
workspace and server.

=item name XXX

=item tag XXX

=back

=head2 C<new_post()>

XXX

=cut

sub new_post {
    my $self = shift;

    my $post_name = $self->_make_name;
    $self->edit_page(page => $post_name);

    my $tags = $self->{tags} || die 'tags is mandatory';
    for my $tag (@$tags) {
        $self->{rester}->put_pagetag( $post_name, $tag );
    }
}

sub _make_name {
    my $self = shift;
    my $name = $self->{name} || die 'name is mandatory';
    my ($year, $month, $date) = (localtime)[5,4,3];
    $year += 1900;
    $month++;

    return sprintf('%s, %4d-%02d-%02d', $name, $year, $month, $date);
}

1;

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-editpage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Socialtext::EditBlog

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
