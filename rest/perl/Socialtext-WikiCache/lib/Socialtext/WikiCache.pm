package Socialtext::WikiCache;
use strict;
use warnings;
use Socialtext::Resting;
use Socialtext::WikiCache::Util qw/set_contents get_contents/;
use JSON;
use File::Path qw/mkpath/;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = {
        cache_dir => "$ENV{HOME}/.st-rest",
        @_,
    };
    bless $self, $class;

    # Make sure our rester is not a wikicache rester
    if (ref($self->{rester}) eq 'Socialtext::WikiCache::Resting') {
        # Create a new rester with the same config
        $self->{rester} = Socialtext::Resting->new(
            server => $self->{rester}->server,
            workspace => $self->{rester}->workspace,
            username => $self->{rester}->username,
            password => $self->{rester}->password,
        );
    }

    return $self;
}

sub cache_dir { shift->{cache_dir} }

sub sync {
    my $self = shift;
    my $force = shift;

    my $r = $self->{rester};
    $r->accept('application/json');
    print "Fetching page list...\n";
    my $pages_json = $r->get_pages;
    my $pages = jsonToObj($pages_json);

    # Fetch details
    $r->json_verbose(1);
    for my $page (@$pages) {
        my $page_file = $self->page_file($page->{page_id});
        if (!$force and -e $page_file) {
            # check for freshness
            my $cur_json = get_contents($page_file);
            my $cur_data = jsonToObj($cur_json);

            if ($cur_data->{modified_time} == $page->{modified_time}) {
                print "$page->{page_id} is fresh - skipping...\n";
                next;
            }
        }

        print "Fetching $page->{page_id} JSON ...\n";
        $r->accept('application/json');
        my $json = $r->get_page($page->{page_id});
        my $data = jsonToObj($json);

        print "Fetching $page->{page_id} HTML ...\n";
        $r->accept('text/html');
        $data->{html} = $r->get_page($page->{page_id});

        set_contents($page_file, objToJson($data));

    }

    # save tags for quick lookups
    $self->cache_taggedpages;
}

sub cache_taggedpages {
    my $self = shift;

    my @files = glob($self->workspace_dir . "/*");
    my %tags;
    for my $f (@files) {
        (my $page_id = $f) =~ s#.+/##;
        my $json = get_contents($f);
        my $data = jsonToObj($json);
        for my $t (@{ $data->{tags} || [] }) {
            push @{ $tags{$t} }, $page_id;
        }
    }

    print "Writing workspace tag file...\n";
    set_contents($self->tag_file, objToJson(\%tags));
}

sub tag_file {
    my $self = shift;
    return $self->workspace_dir . "/.workspace_tags";
}

sub workspace_dir {
    my $self = shift;
    return "$self->{cache_dir}/" . $self->{rester}->workspace;
}

sub page_file {
    my $self = shift;
    my $page_id = shift;
    my $workspace_dir = $self->workspace_dir;

    unless (-d $workspace_dir) {
        mkpath $workspace_dir or die "Can't mkpath $workspace_dir: !";
    }

    return "$workspace_dir/$page_id";
}


1;
