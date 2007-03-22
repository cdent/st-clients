#!/usr/bin/perl
use strict;
use warnings;
use Socialtext::Resting::Getopt qw/get_rester/;
use Data::Dumper;
use Encode;
use lib 'lib';
use CPAN::RSS;

$| = 1; # turn on autoflushing

my $rester = get_rester;

my $releases = CPAN::RSS->new->parse_feed;

my $package_filter = load_package_list( $rester, 'Socialtext CPAN Modules' );
print Dumper $package_filter;
if (%$package_filter) {
    @$releases = grep { $package_filter->{$_->{name}} }
                 @$releases;
}
print Dumper $releases;
exit;
my @releases;

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

sub load_package_list {
    my $rester    = shift;
    my $page_name = shift;
    print "Loading '$page_name' from " . $rester->workspace . "\n";
    my $page = $rester->get_page($page_name);
    my %packages;
    while ($page =~ m/^\*\s+(.+)$/mg) {
        $packages{$1}++;
    }
    return \%packages;
}

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

