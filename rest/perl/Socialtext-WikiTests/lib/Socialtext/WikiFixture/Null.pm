package Socialtext::WikiFixture::Null;
use strict;
use warnings;
use base 'Socialtext::WikiFixture';
use base 'Exporter';

our @EXPORT_OK = qw/get_num_calls/;

my $CALLS;

=head2 get_num_calls

Return the number of calls made to handle_command, and reset the counter.

=cut

sub get_num_calls {
    my $num = $CALLS;
    $CALLS = 0;
    return $num;
}

sub handle_command { $CALLS++ }

1;
