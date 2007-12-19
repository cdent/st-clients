#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Blikistan';
    use_ok 'Blikistan::MagicEngine::Dashboard';
}

my $r = Socialtext::Resting::Mock->new(
    server => 'http://test',
    workspace => 'wksp',
    username => 'fakeuser',
    password => 'fakepass',
);

Last_tagged_page: {
    $r->put_page('Dashboard Template', <<EOT);
[% page = magic.last_tagged_page('foo', 'bar') -%]
title=[% page.title %]
id=[% page.id %]
html=[% page.html %]
EOT
    $r->put_page('page1', 'page 1 - abcd abcde abcdef'); $r->put_pagetag('post1', 'bar');
    $r->put_page('page2', 'page 2 - abcd abcde abcdef'); $r->put_pagetag('post2', 'bar');

#    $r->response->set_always('header', 'Today');

    my $b = Blikistan->new(
        rester => $r,
        magic_engine => 'Dashboard',
    );
    is $b->print_blog, <<EOT;
title=page1
id=page1
html=page 1 - abcd abcde abcdef
EOT
}
