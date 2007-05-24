#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'Socialtext::Resting::Mock';
}

Pages: {
    my $r = Socialtext::Resting::Mock->new;
    is $r->get_page('foo'), 'foo not found';

    # this behaviour is different from ST::Resting
    $r->put_page('foo', 'bar');
    is $r->get_page('foo'), 'bar';
    is $r->get_page('foo'), 'foo not found';
    is_deeply [$r->get_pages], ['foo'];
}

Tags: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_pagetag("Test page", "Taggy");
    $r->put_pagetag("Test page", "Taggity tag");
    my $tags = join (' ', $r->get_pagetags("Test page"));

    like( $tags, qr/Taggity tag/, "Tag with spaces included");

    my @tagged_pages = $r->get_taggedpages('Taggy');
    is( $tagged_pages[0], 'Test page',
        'Test pages is listed in Taggy pages' );

    my $tagged_pages = $r->get_taggedpages('Taggy');
    like( $tagged_pages, qr/^Test page/,
        "Collection methods behave smart in scalar context" );

}
