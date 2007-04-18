#!/usr/bin/env perl

use File::Basename;
use Socialtext::Resting;
use LWP::MediaTypes qw(guess_media_type read_media_types);

read_media_types("/etc/mime.types");

my $find_home = shift;
my $workspace = shift;
my $username = shift;
my $password = shift;
my $server = shift;

my $hammock = Socialtext::Resting->new(
    username => $username,
    password => $password,
    server => $server,
);

$hammock->workspace($workspace);

sub slurp {
    my $attachment_data = shift;
    open ATTACHMENT_DATA, $attachment_data;
    return join '', <ATTACHMENT_DATA>;
}

foreach my $data_dir (`find $find_home -name _data`) {
    chomp $data_dir;
    # We're not supporting revisions
    next if $data_dir =~ /_revisions/;

    my $data = slurp($data_dir . "/attach.URI.dat");

    # the _data directory is within a directory with the *name* of the
    # attachment
    my $filename_path = dirname $data_dir;
    my $parent_page_path = dirname $filename_path;

    # the filename is unescaped directory name
    my $filename = basename($filename_path);
    $filename =~ s/\+/ /g;
    # the page is the unescaped parent of the directory name
    my $page = basename($parent_page_path);
    $page =~ s/\+/ /g;
    my $mime_type = guess_media_type($filename_path);

    $hammock->post_attachment( 
        $page,
        $filename,
        $data,
        $mime_type,
    );
    printf "Filename path: $filename_path\n";
    printf "  Attached \"$filename\" ($mime_type) to \"$page\"\n\n";
}
