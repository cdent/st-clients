package Blikistan::MagicEngine;
use strict;
use warnings;
use HTML::Truncate;
    
sub new {
    my $class = shift;
    my $self = { @_ };
    bless $self, $class;
    return $self;
}

sub print_blog { die 'Subclass must implement' }

sub truncator {
    my $self = shift;
    my $trunc = HTML::Truncate->new;
    $trunc->dont_skip_tags( qw/embed iframe/ );
    $trunc->repair(1);
    $self->{trunc} = $trunc;
}

1;
