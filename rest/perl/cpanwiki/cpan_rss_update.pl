#!/usr/bin/perl
use strict;
use warnings;
use XML::Liberal;
use Socialtext::Resting::Getopt qw/get_rester/;
use LWP::Simple qw/get/;
use Data::Dumper;
use Encode;

$| = 1; # turn on autoflushing

my $rester = get_rester(
    server => 'http://talc.socialtext.net:21029',
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
my @items = $doc->getElementsByTagName('item');
die "No items in $uri!\n" unless @items;
my @releases;
for my $i (@items) {
    my ($title_elem) = $i->getElementsByTagName('title');
    my $package_string = $title_elem->textContent;
    next if $package_string eq 'search.cpan.org';
    unless ($package_string =~ m/(.+)-(v?\d+(?:\.[\d_]+)+)$/) {
        die "Couldn't parse version: $package_string";
    }
    my %release = (
        name => $1,
        version => $2,
    );

    my ($link_elem)  = $i->getElementsByTagName('link');
    $release{link} = $link_elem->textContent;
    $release{pause_id} = $1 if $release{link} =~ m#search\.cpan\.org/~(\w+)/#;

    my ($desc_elem) = $i->getElementsByTagName('description');
    $release{desc} = $desc_elem ? $desc_elem->textContent : 'No description';
    my ($author_elem) = $i->getElementsByTagName('dc:creator');
    $release{author} = $author_elem->textContent;

    push @releases, \%release;
}

=for comment

{ # example
    'link' => 'http://search.cpan.org/~dmaki/XML-RSS-LibXML-0.30_01/',
    'desc' => 'XML::RSS with XML::LibXML',
    'version'  => '0.30_01',
    'name'     => 'XML-RSS-LibXML',
    'author'   => 'Daisuke Maki',
    'pause_id' => 'dmaki'
}

=cut

print "Putting releases onto the wiki ...\n";
my %pause_id;
my %author;
for my $r (@releases) {
    my $continue = 1;
    eval { 
        $continue = put_release_on_wiki($r);
    };
    warn $@ if $@;
    last unless $continue;
}

print "\nUpdating PAUSE ID pages ...\n" if %pause_id;
for my $id (keys %pause_id) {
    my $author = $pause_id{$id};
    put_author_page($id, <<EOT, 'pause_id');
[$author]

{include: [$author]}
EOT
}


print "\nUpdating author pages ...\n" if %author;
for my $id (keys %author) {
    my $releases = $author{$id};
    my $pause_id = $releases->[0]->{pause_id};
    put_author_page($id, <<EOT, 'author');
* "CPAN Page" <http://search.cpan.org/~$pause_id/>

^^ Packages

{search: tag: package AND tag: $pause_id}

EOT
}

exit;

sub put_release_on_wiki {
    my $r = shift;

    my $release_page = "$r->{name}-$r->{version}";
    print sprintf('%50s ', $release_page);
    $rester->get_page($release_page);
    my $code = $rester->response->code;
    if ($code eq '200') {
        print "skipping ...\n";
        return 0;
    }

    $rester->put_page($release_page, <<EOT);
^^ Release Details

*Package:* [$r->{name}]
*Version:* "$r->{version}" <$r->{link}>
*Description:* $r->{desc}
*Author:* "$r->{author}" <http://search.cpan.org/~$r->{pause_id}/>
*PAUSE ID:* "$r->{pause_id}" <http://search.cpan.org/~$r->{pause_id}/>

"$release_page on CPAN" <$r->{link}>

^^ Comments
EOT

    my @release_tags = ('release', $r->{name}, $r->{pause_id}, $r->{version});
    print 'tags: ', join(', ', @release_tags);
    for my $p (@release_tags) {
        $rester->put_pagetag($release_page, $p);
    }

    my $package_page = $r->{name};
    print "\n", sprintf('%50s ', $package_page);
    my $package_page_text = $rester->get_page($r->{name});
    my $comments = "^^ Comments:\n";
    if ($package_page_text =~ m/\Q$comments\E(.+)/s) {
        $comments .= $1;
    }

    $rester->put_page($r->{name}, <<EOT);
*Package:* $r->{name}
*Latest release:* [$release_page]
*Version:* "$r->{version}" <$r->{link}>
*Description:* $r->{desc}
*Author:* "$r->{author}" <http://search.cpan.org/~$r->{pause_id}/>
*PAUSE ID:* {category: $r->{pause_id}}

"Latest release on CPAN: $release_page" <$r->{link}>

^^ All Releases

{category: $r->{name}}


$comments
EOT
    my @package_tags = ('package', $r->{name}, $r->{pause_id}, $r->{version});
    print 'tags: ', join(', ', @package_tags);
    for my $p (@package_tags) {
        $rester->put_pagetag($package_page, $p);
    }

    print "\n";

    # Update author tables
    $pause_id{$r->{pause_id}} = $r->{author};
    push @{ $author{$r->{author}} }, $r;

    return 1;
}

sub put_author_page {
    my $page    = shift;
    my $content = shift;
    my @tags    = @_;
    my $code    = '';
    eval {
        my $existing_page = $rester->get_page($page);
        $code = $rester->response->code;
    };
    warn "Error: get_page($page, 'pause_id'): $@" if $@;
    return unless $code eq '404';

    print "  $page\n";
    eval {
        $rester->put_page($page, $content);
    };
    warn "Error: put_page($page, <content>): $@" if $@;
    for my $t (@tags) {
        eval {
            $rester->put_pagetag($page, $t);
        };
        warn "Error: put_pagetag($page, $t): $@" if $@;
    };
}

