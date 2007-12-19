#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Blikistan';
    use_ok 'Blikistan::MagicEngine::Dashboard';
}

Last_tagged_page: {
    my $r = setup_rester(
        template => <<EOT,
[% page = last_tagged_page('foo', 'bar') -%]
title=[% page.title %]
page_id=[% page.page_id %]
html=[% page.html %]
EOT
    );
    my $b = Blikistan->new(
        rester => $r,
        magic_engine => 'Dashboard',
    );
    is $b->print_blog, <<EOT;
title=Page One
page_id=page_one
html=page 1 abcdefghi
EOT
}

Last_tagged_page_truncated: {
    my $r = setup_rester(
        template => <<EOT,
[% page = last_tagged_page('foo', 'bar', 10) -%]
title=[% page.title %]
page_id=[% page.page_id %]
html=[% page.html %]
EOT
    );
    my $b = Blikistan->new(
        rester => $r,
        magic_engine => 'Dashboard',
    );
    is $b->print_blog, <<EOT;
title=Page One
page_id=page_one
html=page 1 abc&#8230;
EOT
}

Load_names_and_tags: {
    my $r = setup_rester(
        template => <<EOT,
[% pages = names_and_tags('foo', 'bar') -%]
[% FOREACH p IN pages -%]
 name=[% p.name %]
 page_id=[% p.page_id %]
 tags=[% p.tags %]
[% END -%]
EOT
    );
    my $b = Blikistan->new(
        rester => $r,
        magic_engine => 'Dashboard',
    );
    is $b->print_blog, <<EOT;
 name=page_one
 page_id=page_one
 tags=red, green
 name=page_two
 page_id=page_two
 tags=blue, yellow
EOT
}

Blog_posts: {
    my $r = setup_rester(
        template => <<EOT,
[% posts = blog_posts('foo', 'bar') -%]
[% FOREACH p IN posts -%]
 title=[% p.title %]
 author=[% p.author %]
 date=[% p.date %]
 summary=[% p.summary %]
[% END -%]
EOT
    );
    my $b = Blikistan->new(
        rester => $r,
        magic_engine => 'Dashboard',
    );
    is $b->print_blog, <<EOT;
 title=page_one
 author=blah
 date=Thu May 10 12:53:48 2007
 summary=page 1 abcdefghi
 title=page_two
 author=blah
 date=Thu May 10 12:53:48 2007
 summary=page 2 abcdefghi
EOT
}

Blog_posts_trunc: {
    my $r = setup_rester(
        template => <<EOT,
[% posts = blog_posts('foo', 'bar', 0, 6) -%]
[% FOREACH p IN posts -%]
 title=[% p.title %]
 author=[% p.author %]
 date=[% p.date %]
 summary=[% p.summary %]
[% END -%]
EOT
    );
    my $b = Blikistan->new(
        rester => $r,
        magic_engine => 'Dashboard',
    );
    is $b->print_blog, <<EOT;
 title=page_one
 author=blah
 date=Thu May 10 12:53:48 2007
 summary=page 1&#8230;
 title=page_two
 author=blah
 date=Thu May 10 12:53:48 2007
 summary=page 2&#8230;
EOT
}

exit;


sub setup_rester {
    my %opts = @_;
    my $r = Socialtext::Resting::Mock->new(
        server => 'http://test',
        workspace => 'wksp',
        username => 'fakeuser',
        password => 'fakepass',
    );

    $r->put_page('Dashboard Template', $opts{template});
    my $page_json = <<EOT;
{"page_uri":"blah","name":"Page One","page_id":"page_one","modified_time":1178826828,"uri":"page_one","tags":["bar"],"revision_id":20070223113157,"last_edit_time":"2007-02-23 11:31:57 GMT","revision_count":8,"last_editor":"blah","html":"page 1 abcdefghi"}
EOT
    $r->put_page('page_one', $page_json);
    $r->put_pagetag('page_one', $_) for qw/bar red green/;
    my $page_json2 = <<EOT;
{"page_uri":"blah","name":"Page Two","page_id":"page_two","modified_time":1178826828,"uri":"page_two","tags":["bar"],"revision_id":20070223113157,"last_edit_time":"2007-02-23 11:31:57 GMT","revision_count":8,"last_editor":"blah","html":"page 2 abcdefghi"}
EOT
    $r->put_page('page_two', $page_json2); 
    $r->put_pagetag('page_two', $_) for qw/bar blue yellow/;
    return $r;
}
