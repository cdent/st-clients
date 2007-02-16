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

my $rester = Socialtext::Resting::Mock->new;

Regular_edit: {
    $rester->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(page => 'Foo');

    is $rester->get_page('Foo'), 'MONKEY';
}

Edit_no_change: {
    $rester->put_page('Foo', 'MONKEY');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(page => 'Foo');

    # relies on mock rester->get_page to delete from the hash
    is $rester->get_page('Foo'), undef;
}

Edit_with_callback: {
    $rester->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    my $cb = sub { return "Ape\n\n" . shift };
    $ep->edit_page(page => 'Foo', callback => $cb);

    is $rester->get_page('Foo'), "Ape\n\nMONKEY";
}

Edit_with_tag: {
    $rester->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(page => 'Foo', tags => 'Chimp');

    is $rester->get_page('Foo'), 'MONKEY';
    is_deeply $rester->get_pagetags('Foo'), ['Chimp'];
}

Edit_with_tags: {
    $rester->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    my $tags = [qw(one two three)];
    $ep->edit_page(page => 'Foo', tags => $tags);

    is $rester->get_page('Foo'), 'MONKEY';
    is_deeply $rester->{page_tags}{Foo}, $tags;
}

Edit_with_collision: {
  SKIP: {
    unless (qx(which merge) =~ /merge/) {
        skip "No merge tool available", 1;
    }
    close STDIN;
    $rester->put_page('Foo', "Monkey\n");
    $rester->put_page('Foo', "Ape\n");
    $rester->die_on_put(412);
    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(page => 'Foo');

    my $expected_page = <<EOT;
<<<<<<< YOURS
MONKEY
=======
APE
>>>>>>> NEW EDIT
EOT
    is $rester->get_page('Foo'), $expected_page;
  }
}

Extraclude: {
    $rester->put_page('Foo', "Monkey\n");

    local $ENV{EDITOR} = "cp t/extraclude.txt";
    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(page => 'Foo');

    is $rester->get_page('Foo'), <<EOT;
Monkey
{include: [Foo Bar]}
{include: [Bar Baz]}
EOT
    is $rester->get_page('Foo Bar'), "Cows\n";
    is $rester->get_page('Bar Baz'), "Bears are godless killing machines\n";
}

Extraclude_in_page_content: {
    $rester->put_page('Foo', <<EOT);
Monkey
.extraclude [Foo Bar]
Cows
.extraclude
EOT
    $rester->put_page('FOO BAR', '');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(page => 'Foo');

    # $EDITOR will uc() everything
    is $rester->get_page('Foo'), <<EOT;
MONKEY
.extraclude [FOO BAR]
COWS
.extraclude
EOT
    is $rester->get_page('FOO BAR'), '';
}

Pull_includes: {
    $rester->put_page('Foo', <<EOT);
This and
{include: [Bar]}
{include [Baz Defrens]}
EOT
    $rester->put_page('Bar', "Bar page\n");
    $rester->put_page('Baz Defrens', "Baz page\n");

    my $ep = Socialtext::EditPage->new(rester => $rester, pull_includes => 1);
    $ep->edit_page(page => 'Foo');

    # $EDITOR will uc() everything
    is $rester->get_page('Foo'), <<EOT;
THIS AND
{include: [BAR]}
{include: [BAZ DEFRENS]}
EOT
    is $rester->get_page('BAR'), "BAR PAGE\n";
    is $rester->get_page('BAZ DEFRENS'), "BAZ PAGE\n";
}

Edit_last_page: {
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
    $rester->set_taggedpages('coffee', objToJson(\@tagged_pages));
    $rester->put_page('Newer', 'Newer');
    $rester->put_page('Older', 'Older');
    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_last_page(tag => 'coffee');

    # $EDITOR will uc() everything
    is $rester->get_page('Newer'), 'NEWER';
    is $rester->get_page('Older'), 'Older';
}

Edit_from_template: {
    $rester->put_page('Empty', 'Empty not found');
    $rester->put_page('Pookie', 'Template page');
    $rester->put_pagetag('Pookie', 'Pumpkin');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(
        page => 'Empty',
        template => 'Pookie',
    );

    is $rester->get_page('Empty'), 'TEMPLATE PAGE';
    is_deeply $rester->get_pagetags('Empty'), ['Pumpkin'];
}

Template_when_page_already_exists: {
    $rester->put_page('Foo', 'Monkey');
    $rester->put_page('Pookie', 'Template page');

    my $ep = Socialtext::EditPage->new(rester => $rester);
    $ep->edit_page(
        page => 'Foo',
        template => 'Pookie',
    );

    is $rester->get_page('Foo'), 'MONKEY';
}
