#!/usr/bin/perl
use strict;
use warnings;
use XML::Liberal;
use Socialtext::Resting::Getopt qw/get_rester/;
use LWP::Simple qw/get/;
use Data::Dumper;

my $rester = get_rester(
    server => 'http://localhost:21000',
    username => 'devnull1@socialtext.com',
    password => 'd3vnu11l',
    workspace => 'cpan',
);

my $uri = 'http://search.cpan.org/uploads.rdf';
my $rdf = get($uri);
die "Couldn't get rdf" unless $rdf;
my $parser = XML::Liberal->new( 'LibXML' );
my $doc = $parser->parse_string($rdf);

print "Fetching latest cpan rss ...\n";
my @nodes = $doc->getElementsByTagName('title');
my @releases;
for my $n (@nodes) {
    my $package_string = $n->textContent;
    next if $package_string eq 'search.cpan.org';
    unless ($package_string =~ m/(.+)-(v?\d+(?:\.[\d_]+)+)$/) {
        die "Couldn't parse version: $package_string";
    }
    push @releases, {
        name => $1,
        version => $2,
    };
}

print "Putting releases onto the wiki ...\n";
for my $r (@releases) {
    my $page_name = "$r->{name}-$r->{version}";
    print "Starting $page_name ...\n";
    $rester->get_page($page_name);
    my $code = $rester->response->code;
    if ($code eq "200") {
        print "'$page_name' already exists on the wiki\n";
    }
    elsif ($code eq "404") {
        print "'$page_name' -> creating page ...\n";
        $rester->put_page($page_name, <<EOT);
    *Package:* $r->{name}
    *Version:* $r->{version}
EOT
    }
    else {
        print "UNKNOWN RESPONSE CODE: $code\n";
    }

    my $release_tag = $r->{name};
    my @page_tags = ($release_tag);
    for my $p (@page_tags) {
        print "  tag: '$p' ...\n";
        $rester->put_pagetag($page_name, $p);
    }

    $rester->put_page($r->{name}, <<EOT);
*Package:* $r->{name}
*Latest release:* [$page_name]

^^ All Releases

{search: tag: $release_tag}
EOT
    $rester->put_pagetag($r->{name}, 'package');
}

