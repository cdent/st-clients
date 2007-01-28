package Socialtext::SuiteTwo::Mash;
use strict;
use warnings;

our $VERSION = '0.01_02';

use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use JSON::Syck;
use Text::Context;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw[base workspace user pass ua]);

sub get_pages_for_tag {
    my ($self, $tag) = @_;
    my $pages = $self->_make_json_request($self->_url_tag($tag));
    return $pages;
}

sub get_all_tags {
    my $self = shift;
    my $all_tags = $self->_make_json_request($self->_url_all_tags);
    my %tags;
    for my $tag (@{$all_tags}) {
        next unless $tag->{name} && $tag->{page_count};
        $tags{$tag->{name}} = $tag;
    }
    return \%tags;
}

sub get_search_results {
    my ($self, $query) = @_;
    my $search = $self->_make_json_request($self->_url_search($query));
    my @results;
    for my $result (@{$search}) {
        eval {
            my $page = $self->_make_text_request($self->_url_page($result->{uri}));
            $result->{context} = $self->_get_query_context($page, $query);
            push @results, $result;
        };
        die $@ if $@ && !($@ =~ /Failed request/);
    }
    return \@results;
}

sub _get_query_context {
    my ($self, $text, $query) = @_;
    my @keywords = split /\s+/, $query;

    my $context = Text::Context->new($text, @keywords);
    return {
        text    => $context->as_text,
        html    => $context->as_html,
    };
}

sub _make_text_request {
    my ($self, $url) = @_;
    my $resp = $self->_make_request(GET => $url => [
        Accept => 'text/x.socialtext-wiki',
    ]);
    die "Failed request for: $url: " . $resp->code . "\n"
        unless $resp->is_success;
    return $resp->content;
}

sub _make_json_request {
    my ($self, $url) = @_;
    my $resp = $self->_make_request(GET => $url => [
        Accept => 'application/json',
    ]);
    die "Failed request for: $url: " . $resp->code . "\n"
        unless $resp->is_success;
    return JSON::Syck::Load($resp->content);
}

sub _make_request {
    my $self = shift;
    my $req  = HTTP::Request->new(@_);

    $req->authorization_basic($self->user, $self->pass);

    $self->ua(LWP::UserAgent->new) unless $self->ua;

    return $self->ua->request($req);
}

sub _url_all_tags {
    my $self = shift;
    sprintf "%s/workspaces/%s/tags",
        $self->base,
        $self->workspace;
}

sub _url_search {
    my $self = shift;
    sprintf "%s/workspaces/%s/pages?q=%s",
        $self->base,
        $self->workspace,
        URI::Escape::uri_escape_utf8(shift);
}

sub _url_tag {
    my $self = shift;
    sprintf "%s/workspaces/%s/tags/%s/pages",
        $self->base,
        $self->workspace,
        URI::Escape::uri_escape_utf8(shift);
}

sub _url_page {
    my $self = shift;
    sprintf "%s/workspaces/%s/pages/%s",
        $self->base,
        $self->workspace,
        shift;
}

1;
