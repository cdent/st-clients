package Socialtext::WikiCache;
use strict;
use warnings;
use Socialtext::Resting;
use Socialtext::WikiCache::Util qw/set_contents/;
use JSON;
use File::Path qw/mkpath/;

sub new {
    my $class = shift;
    my $self = {
        cache_dir => "$ENV{HOME}/.st-rest",
        @_,
    };
    bless $self, $class;
    return $self;
}

sub cache_dir { shift->{cache_dir} }

sub sync {
    my $self = shift;
    my $r = $self->{rester};
    $r->accept('text/plain');
    my @pages = $r->get_pages;

    # Fetch details
    for my $page (@pages) {
        $r->accept('application/json');
        my $json = $r->get_page($page);
        my $data = jsonToObj($json);
        my $page_id = $data->{page_id};

        my $page_dir = $self->page_dir($page_id);
        -d $page_dir or mkpath $page_dir or die "Can't mkpath $page_dir: $!";

        set_contents("$page_dir/json", $json);
        $r->accept('text/x.socialtext-wiki');
        set_contents("$page_dir/wikitext", $r->get_page($page));
    }
}

sub page_dir {
    my $self = shift;
    my $page_id = shift;
    return "$self->{cache_dir}/pages/" 
          . $self->{rester}->workspace
          . "/$page_id";
}


1;
