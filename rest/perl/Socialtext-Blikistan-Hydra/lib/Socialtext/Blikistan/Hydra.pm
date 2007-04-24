package Socialtext::Blikistan::Hydra;
use strict;
use warnings;

our $VERSION = '0.01';

use Apache;
use Apache::Constants qw (OK);
use Socialtext::Resting::Getopt qw/get_rester/;
use Blikistan;

sub handler {
    my $r = shift;

    my $rester = get_rester(
        'rester-config' => '/etc/hydra-rester.conf',
    );
    die "no server!" unless $rester->server; 

    my %magic_opts;

    if ($r->uri =~ m#^/hydra/search/pages#) {
	my %args = $r->args;
	my $search = $args{'q'};
	$magic_opts{search} = $search;
    } elsif ($r->uri =~ m#^/hydra/search/([^/]+)$#) {
	$magic_opts{search} = $1;
    } elsif ($r->uri =~ m#^/hydra/(\w+)#) {
        $magic_opts{subpage} = $1;
    }

    my $b = Blikistan->new(
	magic_engine => 'perlSite',
        rester => $rester,
        magic_opts => \%magic_opts,
    );

    $r->content_type('text/html');
    $r->status_line("201 Ok");
    $r->send_http_header();
    $r->print ($b->print_blog);

    return OK;
}

1;
