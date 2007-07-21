package Socialtext::WikiCache::Resting;
use strict;
use warnings;
use Socialtext::WikiCache;
use base 'Socialtext::Resting';
use Socialtext::WikiCache::Util qw/get_contents/;
use JSON;

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
    my $page_file = $self->{_wc}->page_file($page);
    my $content = get_contents($page_file);
    return $content if $accept =~ /json/;

    my $data = jsonToObj($content);
    return $data->{wikitext};
}

1;
