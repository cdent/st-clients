use Test::More;
use Socialtext::Resting;
use IPC::Run;

use strict;
use warnings;

plan tests => 14;

# Put the page
my $strut_user = 'rest-tester@socialtext.com';
my $Strutter = new_strutter();
my $page_content = "This is a\nfile thing here\n";
eval { $Strutter->put_page("Test page", $page_content);};
my $network_skip = 1 if $@;

SKIP: {
    skip "unable to access test server", 5 if $network_skip;
    # Get it back and check it
    my $content = $Strutter->get_page("Test page");

    like ($content, qr/file thing here/, 
            'Content has both lines');

    # Put 2 attachments
    my $text_content = readfile("t/filename.txt");
    my $jpg_content  = readfile("t/file.jpg");
    my $text_id = $Strutter->post_attachment(
            "Test page", "filename.txt", $text_content, "text/plain");
    my $jpeg_id = $Strutter->post_attachment(
            "Test page", "file.jpg", $jpg_content, "image/jpeg");

    my $retrieved_text = $Strutter->get_attachment($text_id);
    my $retrieved_jpeg = $Strutter->get_attachment($jpeg_id);
    is ($text_content, $retrieved_text, "text attachment roundtrips");
    is ($jpg_content, $retrieved_jpeg, "jpeg attachment roundtrips");

    # Set a tag or two
    $Strutter->put_pagetag("Test page", "Taggy");
    $Strutter->put_pagetag("Test page", "Taggity tag");
    my $tags = join (' ', $Strutter->get_pagetags("Test page"));

    like( $tags, qr/Taggity tag/, "Tag with spaces included");

    my @tagged_pages = $Strutter->get_taggedpages('Taggy');
    is( $tagged_pages[0], 'Test page',
        'Test pages is listed in Taggy pages' );

    my $tagged_pages = $Strutter->get_taggedpages('Taggy');
    like( $tagged_pages, qr/^Test page/,
        "Collection methods behave smart in scalar context" );

    Get_homepage: {
        is $Strutter->get_homepage, 'socialtext_rest_server_test';
    }

    Invalid_workspace: {
        $Strutter->workspace('st-no-existy');
        is $Strutter->get_homepage, undef;
    }

    Get_user: {
        my $user = $Strutter->get_user( $strut_user );
        is $user->{ email_address }, $strut_user;
    }
}

Name_to_id: {
    is $Strutter->name_to_id('Water bottle'), 'water_bottle';
    is Socialtext::Resting::name_to_id('Water bottle'), 'water_bottle';
}

Perl_hash_accept_type: {
    my $r = new_strutter();
    $r->accept('perl_hash');
    isa_ok scalar($r->get_page('Test Page')), 'HASH';
    isa_ok scalar($r->get_pagetags('Test Page')), 'ARRAY';
    isa_ok scalar($r->get_taggedpages('Taggy')), 'ARRAY';
}

exit;

sub new_strutter {
    return Socialtext::Resting->new(
        username  => $strut_user,
        password  => 'dozing',
        server    => 'http://www.socialtext.net',
        workspace => 'st-rest-test',
    );
}

sub readfile {
    my ($filename) = shift;
    if (! open (NEWFILE, $filename)) {
        print STDERR "$filename could not be opened for reading: $!\n";
        return;
    }
    local $/;
    my $data = <NEWFILE>;
    close (NEWFILE);

    return ($data);
}
