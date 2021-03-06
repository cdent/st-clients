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
    my $content = $self->_page_json($page);
    return $content if $accept =~ /json/;

    my $data = jsonToObj($content);
    if ($accept eq 'text/html') {
        return $data->{html} || '';
    }

    return $data->{wikitext} || "$page not found";
}

sub get_pagetags {
    my $self = shift;
    my $page = shift;

    my $accept = $self->accept || '';
    my $json = $self->_page_json($page);
    my $data = jsonToObj($json);

    if ($accept eq 'text/plain') {
        return join "\n", @{ $data->{tags} };
    }

    die "get_pagetags not implemented for accept type $accept";
}

sub get_taggedpages {
    my $self = shift;
    my $tag  = shift;
    my $accept = $self->accept || '';

    my $tag_file = $self->{_wc}->tag_file;
    my $json = get_contents($tag_file);
    my $tag_data = jsonToObj($json);

    if ($accept eq 'text/plain') {
        return @{ $tag_data->{$tag} || [] };
    }

    die "get_taggedpages not implemented for accept type $accept";
}

sub response { $_[0]->{response} }

sub _page_json {
    my $self = shift;
    my $page = shift;

    my $file = $self->{_wc}->page_file($page);
    if (-e $file) {
        $self->{response} = Socialtext::WikiCache::Response->new(200);
        return get_contents($file);
    }
    
    $self->{response} = Socialtext::WikiCache::Response->new(404);
    return "";
}

package Socialtext::WikiCache::Response;
use strict;
use warnings;

sub new {
    my ($class, $code) = @_;
    bless { code => $code }, $class;
}

sub code { $_[0]->{code} }
sub content { '' }

1;
