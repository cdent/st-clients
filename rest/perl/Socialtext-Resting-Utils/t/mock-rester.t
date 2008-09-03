#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;

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

Misc: {
    my $r = Socialtext::Resting::Mock->new;
    my %misc_functions = (
        json_verbose => 1,
        accept => 'poop',
        order => 'latest',
    );
    for my $method (keys %misc_functions) {
        eval { $r->$method($misc_functions{$method}) };
        is $@, '';
        is $r->{$method}, $misc_functions{$method};
    }
}

Response: {
    my $r = Socialtext::Resting::Mock->new;
    my $resp = $r->response;
    isa_ok $resp, 'HTTP::Response';
    is $resp->code, 200;
}
