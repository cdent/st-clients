#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Socialtext::WikiCache';
}

my $mock = Socialtext::Resting::Mock->new(workspace => 'w');

New_rester: {
    my $r = Socialtext::WikiCache->new;
    isa_ok $r, 'Socialtext::WikiCache';
    is $r->cache_dir, "$ENV{HOME}/.st-rest";
}

Sync_workspace: {
    my $cache_dir = "t/cache.$$";
    my $r = Socialtext::WikiCache->new(
        cache_dir => $cache_dir,
        rester => $mock,
    );

# This doesn't work.  We need to improve Socialtext::Resting::Mock to allow it
# to store json and wikitext representations in memory.
# The ::Mock is really ::InMemory
# 
#    $mock->put_page('Foo', 'foo content');
#    $r->sync;
#    ok -d $cache_dir, "-d $cache_dir";
}
