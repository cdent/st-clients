use Test::More;
use Socialtext::Resting;
use IPC::Run;

use strict;
use warnings;

plan tests => 6;

my $Strutter = Socialtext::Resting->new(
        username => 'rest-tester@socialtext.com',
        password => 'dozing',
        server   => 'http://www.socialtext.net',
);

$Strutter->workspace('st-rest-test');

# Put the page
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
