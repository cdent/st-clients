#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;
use Socialtext::EditPage; # _read_file and _write_file
use File::Path qw/mkpath rmtree/;
use Fatal qw/mkpath rmtree/;
use JSON;

BEGIN {
    use_ok 'Socialtext::Resting::LocalCopy';
}

# Test data
my $foo = {
    json => <<'EOT',
{"page_uri":"https://www.socialtext.net/st-sandbox/index.cgi?foo","page_id":"foo","name":"Foo","wikitext":"Foocontent\n","modified_time":1188427118,"tags":["Footag"],"uri":"foo","revision_id":20070829223838,"html":"<div class=\"wiki\">\n<p>\nFoocontent</p>\n</div>\n","last_edit_time":"2007-08-29 22:38:38 GMT","last_editor":"luke.closs@socialtext.com","revision_count":15}
EOT
    tag => 'Footag',
    expected => {
        page_id => 'foo',
        name => 'Foo',
        wikitext => "Foocontent\n",
        tags => ['Footag'],
    },
};

Simple_pull_push: {
    my $src = Socialtext::Resting::Mock->new;
    $src->put_page('Foo', $foo->{json});
    $src->put_pagetag('Foo', $foo->{tag});
    my $src_lc = Socialtext::Resting::LocalCopy->new( rester => $src );
    my $tmpdir = _make_tempdir();
    $src_lc->pull($tmpdir);


    # Test that the content was saved
    my $file = "$tmpdir/foo";
    ok -e $file, "-e $file";
    my $json;
    eval { $json = jsonToObj( Socialtext::EditPage::_read_file($file) ) };
    is $@, '';
    is_deeply $json, $foo->{expected}, 'json object matches';

    # Push the content up to a workspace
    my $dst = Socialtext::Resting::Mock->new;
    my $dst_lc = Socialtext::Resting::LocalCopy->new( rester => $dst );
    $dst_lc->push($tmpdir);

    # Test that the workspace was populated correctly
    is $dst->get_page($foo->{expected}{name}), $foo->{expected}{wikitext}, 'dst wikitext';
    is_deeply [ $dst->get_pagetags($foo->{expected}{name}) ], 
        $foo->{expected}{tags}, 'dst tags';
}

# Note Attachment handling is not yet implemented


exit;

sub _make_tempdir {
    my $dir = "t/localstore.$$";
    rmtree $dir if -d $dir;
    mkpath $dir;
    END { rmtree $dir if $dir and -d $dir }
    return $dir;
}

