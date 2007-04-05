package Socialtext::Blikistan::DevBlogs;
use strict;
use warnings;

our $VERSION = '0.01';

use Apache2::RequestRec ();
use Apache2::RequestIO ();

use Apache2::Const -compile => qw(OK);
use Socialtext::Resting::Getopt qw/get_rester/;
use Blikistan;

sub handler {
    my $r = shift;

    my $rester = get_rester(
        'rester-config' => '/etc/stoss-rester.conf',
    );
    die "no server!" unless $rester->server; 

    my %magic_opts;
    if ($r->uri =~ m#^/(\w+)#) {
        $magic_opts{subblog} = $1;
    }
    my $b = Blikistan->new(
        rester => $rester,
        magic_opts => \%magic_opts,
    );

    $r->content_type('text/html');
    print $b->print_blog;

    return Apache2::Const::OK;
}

1;
