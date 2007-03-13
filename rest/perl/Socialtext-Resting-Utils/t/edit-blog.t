#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/; #tests => 23;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Socialtext::EditBlog';
}

# Don't use a real editor
$ENV{EDITOR} = 't/mock-editor.pl';

my $rester = Socialtext::Resting::Mock->new;

New_post: {
    my $tag = q{Jebus's Blog};
    Socialtext::EditBlog->new(
        rester => $rester,
        name => 'jebus',
        tags => [$tag],
    )->new_post();

    my @posts = $rester->get_taggedpages($tag);
    is_deeply \@posts, [test_make_name('jebus')];
}


sub test_make_name {
    my @ymd = (localtime)[5,4,3];
    $ymd[0] += 1900; $ymd[1]++;
    return sprintf('%s, %4d-%02d-%02d', shift, @ymd);
}
