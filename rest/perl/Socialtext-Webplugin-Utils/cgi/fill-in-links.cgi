#!/usr/bin/perl
use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw/:standard/;
use Socialtext::Resting::Getopt qw/get_rester/;
use FindBin;
use lib "$FindBin::Bin/lib";
use Socialtext::Garden::FillInLinks;

my $rester = get_rester( 
    'rester-config' => '/etc/socialtext/gardener-rester.conf',
);

print header();
eval {
    print Socialtext::Garden::FillInLinks->new(
        cgi => CGI->new(),
        rester => $rester,
    )->run;

};
if ($@) {
    print h1("Error: $@"), pre(<<EOT);
USAGE: fill-in-links.cgi?&lt;options>

Create pages from a template for incipient links on a page.

Example:
  fill-in-links.cgi?workspace=admin&page=project_page&matching=Story:&template=story_template

Mandatory Options:
- workspace - the workspace where this all takes place
- page - the page to look for links on
- matching - some characters that the link name must contain
- template - the page to clone into the new page

EOT
}
