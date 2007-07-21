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
    $r->json_verbose(1);
    for my $page (@pages) {
        $r->accept('application/json');
        my $json = $r->get_page($page);
        my $data = jsonToObj($json);
        my $page_id = $data->{page_id};

        my $page_file = $self->page_file($page_id);
        set_contents($page_file, $json);
    }
}

sub page_file {
    my $self = shift;
    my $page_id = shift;
    my $workspace_dir = "$self->{cache_dir}/" . $self->{rester}->workspace;

    unless (-d $workspace_dir) {
        mkpath $workspace_dir or die "Can't mkpath $workspace_dir: !";
    }

    return "$workspace_dir/$page_id";
}


1;
