package Socialtext::Resting::LocalCopy;
use strict;
use warnings;
use Fatal qw/open close/;
use JSON;

sub new {
    my $class = shift;
    my $self = { @_ };

    die 'rester is mandatory' unless $self->{rester};
    bless $self, $class;
    return $self;
}

sub pull {
    my $self = shift;
    my %opts = @_;
    my $dir  = $opts{dir};
    my $tag  = $opts{tag};
    my $r    = $self->{rester};

    $r->accept('text/plain');
    my @pages = $tag ? $r->get_taggedpages($tag) : $r->get_pages();
    $r->accept('application/json');
    $r->json_verbose(1);
    for my $p (@pages) {
        print "Saving $p ...\n";
        my $json = $r->get_page($p);
        my $obj = jsonToObj($json);

        # Trim the content
        my %to_keep = map { $_ => 1 } $self->keys_to_keep;
        for my $k (keys %$obj) {
            delete $obj->{$k} unless $to_keep{$k};
        }

        my $file = "$dir/$obj->{page_id}";
        open(my $fh, ">$file");
        print $fh objToJson($obj);
        close $fh;
    }
}

sub keys_to_keep { qw/page_id name wikitext tags/ }

sub push {
    my $self = shift;
    my %opts = @_;
    my $dir  = $opts{dir};
    my $tag  = $opts{tag};
    my $r    = $self->{rester};

    die "Sorry - push by tag is not yet implemented!" if $tag;

    my @files = glob("$dir/*");
    for my $f (@files) {
        open(my $fh, $f);
        local $/ = undef;
        my $obj = jsonToObj(<$fh>);
        close $fh;

        print "Putting $obj->{page_id} ...\n";
        $r->put_page($obj->{name}, $obj->{wikitext});
        $r->put_pagetag($obj->{name}, $_) for @{ $obj->{tags} };
    }
}

1;
