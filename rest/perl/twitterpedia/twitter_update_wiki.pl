#!/usr/bin/perl
use strict;
use warnings;
use XML::Liberal;
use Socialtext::Resting::Getopt qw/get_rester/;
use Data::Dumper;
use Net::Twitter;
$| = 1; # turn off autoflush

my $rester = get_rester(
    server => 'http://talc.socialtext.net:21029',
    username => 'devnull1@socialtext.com',
    password => 'd3vnu11l',
    workspace => 'stwittiki',
);

my $twitter = Net::Twitter->new(
    username => 'socialtext',
    password => 'twittertext',
);

print "Getting twitter data ...\n";
my $twitters = $twitter->friends_timeline;
my $force = 0;
for my $t (@$twitters) {
    # make the status page
    my $status_text = $t->{text} || $t->{id};
    my $screen_name = $t->{user}{screen_name};
    my $status_page = "$screen_name - " . substr($status_text, 0, 50);
    $status_page = fix_uri($status_page);
    $status_page =~ s/\//_/g;
    printf "Status: %66s - ", $status_page;
    if (!$force and get_page($status_page)) {
        print "skipping ...\n";
        next;
    }
    $rester->put_page($status_page, make_status_page($t));
    put_tags($status_page, 'status', $screen_name);

    # make the person page if it doesn't exist
    my $person_page = $screen_name;
    printf "\nFriend: %66s - ", $person_page;
    if (!$force and get_page($person_page)) {
        print "skipping ...\n";
        next;
    }
    put_page($person_page, make_person_page($t));
    put_tags($person_page, 'person', $screen_name, $t->{user}{location});
    
    print "\n";

    # Check for custom pages
    if ($status_text =~ m#^\[([^\]]+)\]:?\s*(.+)#) {
        my ($page, $text) = ($1, $2);
        print "Extracluding $page ... ";
        my $existing_text = get_page($page);
        $text = "$existing_text\n---\n$text" if $existing_text;
        put_page($page, $text);
        put_tags($page, $screen_name, $t->{user}{location}, 'twitterpage');
        print "\n";
    }
}
print "\n";
exit;

sub fix_uri {
    my $uri = shift || '';
    $uri =~ s#\\/#/#g;
    $uri =~ s#\s$##;
    return $uri;
}

# XXX could add $image_uri
sub make_person_page {
    my $t = shift;
    my $url = fix_uri($t->{user}{url});
    my $name = $t->{user}{name};
    my $title = $url ? qq(^ "$name" <$url>\n) : qq(^ $name\n);
    my $location = $t->{user}{location} || '';
    $location = qq(*Location:* {category: $location}\n) if $location;
    my $desc = $t->{user}{description} || '';
    my $rss = $rester->server . "/noauth/feed/workspace/"
              . $rester->workspace . "?category=$t->{user}{screen_name}";
    return <<EOT;
$title
$desc

$location

^^ Statuses

{fetchrss $rss}
EOT
}

sub make_status_page {
    my $t = shift;
    my $status = fix_uri($t->{text});
    return <<EOT;
^^ $status

*Created by:* [$t->{user}{screen_name}]
*Created at:* $t->{created_at}
EOT
}


sub put_tags {
    my $page = shift;
    for my $t (grep { defined and length } @_) {
        print "'$t' ";
#        warn "putting pagetag ($page, $t)";
        $rester->put_pagetag($page, $t);
    }
}

sub get_page {
    my $page = shift;
#    warn "getting page ($page)";
    my $text = $rester->get_page($page);
    return '' if $rester->response->code eq 404;
    return $text;
}

sub put_page {
    my $page = shift;
    my $text = shift;
#    warn "putting page ($page)";
    $rester->put_page($page, $text);
}

