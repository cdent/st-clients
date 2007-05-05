package Socialtext::WikiCache::Resting;
use strict;
use warnings;
use Socialtext::WikiCache;
use base 'Socialtext::Resting';
use Socialtext::WikiCache::Util qw/get_contents/;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);
    $self->{_wc} = Socialtext::WikiCache->new( rester => $self );

    return $self;
}

sub get_page {
    my $self = shift;
    my $page = shift;

    my $accept = $self->accept || '';
    my $page_dir = $self->{_wc}->page_dir($page);
    if ($accept =~ /json/) {
        return get_contents("$page_dir/json");
    }
    return get_contents("$page_dir/wikitext");
}

1;
