#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 23;
use lib 'lib';
use JSON;

BEGIN {
    use_ok 'Socialtext::EditPage';
    use_ok 'Socialtext::Resting::Mock';
}

# Don't use a real editor
$ENV{EDITOR} = 't/mock-editor.pl';

Regular_edit: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    is $r->get_page('Foo'), 'MONKEY';
}

Edit_no_change: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'MONKEY');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    # relies on mock rester->get_page to delete from the hash
    is $r->get_page('Foo'), 'Foo not found';
}

Edit_with_callback: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    my $cb = sub { return "Ape\n\n" . shift };
    $ep->edit_page(page => 'Foo', callback => $cb);

    is $r->get_page('Foo'), "Ape\n\nMONKEY";
}

Edit_with_tag: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo', tags => 'Chimp');

    is $r->get_page('Foo'), 'MONKEY';
    is_deeply [$r->get_pagetags('Foo')], ['Chimp'];
}

Edit_with_tags: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    my $tags = [qw(one two three)];
    $ep->edit_page(page => 'Foo', tags => $tags);

    is $r->get_page('Foo'), 'MONKEY';
    is_deeply [ $r->get_pagetags('Foo') ], $tags;
}

Edit_with_collision: {
  SKIP: {
    unless (qx(which merge) =~ /merge/) {
        skip "No merge tool available", 1;
    }
    close STDIN;
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', "Monkey\n");
    $r->put_page('Foo', "Ape\n");
    $r->die_on_put(412);
    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    my $expected_page = <<EOT;
<<<<<<< YOURS
MONKEY
=======
APE
>>>>>>> NEW EDIT
EOT
    is $r->get_page('Foo'), $expected_page;
  }
}

Extraclude: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', "Monkey\n");

    # Load up a fancy faked editor that copies in an extraclude.
    my $fancy_cp = File::Temp->new();
    chmod 0755, $fancy_cp->filename;
    print $fancy_cp "#!/bin/sh\ncp t/extraclude.txt \$1\n";
    $fancy_cp->close();
    local $ENV{EDITOR} = $fancy_cp->filename;

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    is $r->get_page('Foo'), <<EOT;
Monkey
{include: [Foo Bar]}
{include: [Bar Baz]}
EOT
    is $r->get_page('Foo Bar'), "Cows\n";
    is $r->get_page('Bar Baz'), "Bears are godless killing machines\n";
}

Extraclude_in_page_content: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', <<EOT);
Monkey
.extraclude [Foo Bar]
Cows
.extraclude
EOT
    $r->put_page('FOO BAR', '');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    # $EDITOR will uc() everything
    is $r->get_page('Foo'), <<EOT;
MONKEY
.extraclude [FOO BAR]
COWS
.extraclude
EOT
    is $r->get_page('FOO BAR'), '';
}

Pull_includes: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', <<EOT);
This and
{include: [Bar]}
{include [Baz Defrens]}
EOT
    $r->put_page('Bar', "Bar page\n");
    $r->put_page('Baz Defrens', "Baz page\n");

    my $ep = Socialtext::EditPage->new(rester => $r, pull_includes => 1);
    $ep->edit_page(page => 'Foo');

    # $EDITOR will uc() everything
    is $r->get_page('Foo'), <<EOT;
THIS AND
{include: [BAR]}
{include: [BAZ DEFRENS]}
EOT
    is $r->get_page('BAR'), "BAR PAGE\n";
    is $r->get_page('BAZ DEFRENS'), "BAZ PAGE\n";
}

Edit_last_page: {
    my $r = Socialtext::Resting::Mock->new;
    my @tagged_pages = (
        { 
            modified_time => 3,
            name => 'Newer',
            page_id => 'Newer',
        },
        {
            modified_time => 1,
            name => 'Older',
            page_id => 'Older',
        },
    );
    $r->set_taggedpages('coffee', objToJson(\@tagged_pages));
    $r->put_page('Newer', 'Newer');
    $r->put_page('Older', 'Older');
    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_last_page(tag => 'coffee');

    # $EDITOR will uc() everything
    is $r->get_page('Newer'), 'NEWER';
    is $r->get_page('Older'), 'Older';
}

Edit_from_template: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Empty', 'Empty not found');
    $r->put_page('Pookie', 'Template page');
    $r->put_pagetag('Pookie', 'Pumpkin');
    $r->response->code(404);

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(
        page => 'Empty',
        template => 'Pookie',
    );

    is $r->get_page('Empty'), 'TEMPLATE PAGE';
    is_deeply [$r->get_pagetags('Empty')], ['Pumpkin'];
}

Template_when_page_already_exists: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');
    $r->put_page('Pookie', 'Template page');
    $r->response->code(200);

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(
        page => 'Foo',
        template => 'Pookie',
    );

    is $r->get_page('Foo'), 'MONKEY';
}
