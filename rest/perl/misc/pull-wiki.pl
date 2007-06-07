#!/usr/bin/perl

#
# wiki-git - a tool for flowing page changes from one workspace to another.
#
# This tool uses git [1] to track changes to wiki pages, and apply those
# changes to a different workspace.  git tracks the changes, and intelligently
# merges to reduce conflicts.  If a conflict does happen, it is put in a .pre
# block on the wiki, for someone to resolve later.
#
# [1] - http://git.or.cz/
#

use strict;
use warnings;
use Socialtext::Resting::Getopt qw/get_rester/;
use Data::Dumper;
use Getopt::Long;
$| = 1;

my $pull_tag      = 'pullme';
my $page_data_dir = "pages";
my $src_config;
my $dst_config;
GetOptions(
    'tag=s' => \$pull_tag,
    'src=s' => \$src_config,
    'dst=s' => \$dst_config,
) or usage();

usage() unless $src_config and -f $dst_config;
usage() unless $dst_config and -f $dst_config;

my $src_rester = get_rester( 'rester-config' => $src_config );
my $dst_rester = get_rester( 'rester-config' => $dst_config );
my $src_workspace = $src_rester->workspace;
my $dst_workspace = $dst_rester->workspace;

if (! -d '.git') {
    run("git-init");
    mkdir $page_data_dir;
    run("touch $page_data_dir/.exists");
    run("git-add $page_data_dir");
    run("git-commit -m 'create empty initial repo'");
}

# Get the list of pages we want to merge around
my @to_pull = pages_to_pull($src_rester, $pull_tag);
unless (@to_pull) {
    print "No pages tagged '$pull_tag' in $src_workspace ...\n";
    exit;
}

print_title("Pull changes from the source workspace into a separate branch");
change_branch($src_workspace);
fetch_pages_from($src_rester, @to_pull);
git_commit("add pages from $src_workspace");

print_title("Fetch the pages from the destination workspace");
run("git-checkout master");
change_branch($dst_workspace);
fetch_pages_from($dst_rester, @to_pull);
run("git add $page_data_dir");
git_commit("add pages from $dst_workspace");

# XXX
# - I'm not sure that we want to commit the conflict.  I think it would be
# better to leave the conflict there and upload it to the wiki.  If it gets
# resolved on the wiki, it'll come down for the next update.
#
print_title("Merge changes into the destination branch");
print qx(git-merge $src_workspace 2>&1);
# resolve conflicts by checking them in
my %files = map { $_ => 1 } split /\n/, qx(git-diff --name-only);
for my $f (keys %files) {
    print "Conflict in $f ... force resolving ...\n";
    run("git-add $f");
}
git_commit("Merged pages from $src_workspace into $dst_workspace");

print_title("Push pages out to the dst_workspace");
push_pages_to($dst_rester, @to_pull);

exit;


sub push_pages_to {
    my $r = shift;
    my $wksp = $r->workspace;
    my @pages = @_;

    $r->workspace($wksp);
    $r->accept('text/x.socialtext-wiki');
    for my $p (@pages) {
        print "Putting page $p to $wksp... ";
        my $local_content = pretify_conflicts( $p, $wksp );
        # XXX Race condition here if wiki is updated
        my $wiki_content = $r->get_page($p);
        if ($local_content eq $wiki_content) {
            print "not changed, skipping!\n";
            next;
        }
        print "changed!\n";
        $r->put_page($p, $local_content);
    }
}

sub fetch_pages_from {
    my $r = shift;
    my $wksp = $r->workspace;
    my @pages = @_;

    $r->accept('text/x.socialtext-wiki');
    for my $p (@pages) {
        print "Fetching page $p from $wksp ...\n";
        my $content = $r->get_page($p);
        next unless $r->response->code == 200;
        save_page($p, $content);
    }
}

sub pages_to_pull {
    my $r = shift;
    my $tag = shift;
    $r->accept('text/plain');
    return $r->get_taggedpages($tag);
}

sub run {
    print "Running: @_\n";
    system(@_) and die "Couldn't run @_";
}

sub save_page {
    my $name = shift;
    my $content = shift;

    $name = "$page_data_dir/$name";

    my $to_add = !-d $name;
    print "Saving page $name to disk ...\n";
    open(my $fh, ">$name") or die "Can't open $name: $!";
    print $fh $content;
    close $fh or die "Can't write $name: $!";

    if ($to_add) {
        print "Adding $name to git ...\n";
        run("git add $name");
    }
}

sub read_file {
    my $name = shift;

    $name = "$page_data_dir/$name";
    open(my $fh, $name) or die "Can't open $name: $!";
    local $/;
    return <$fh>;
}

sub git_commit {
    my $msg = shift;

    my $status = qx(git-status);
    if ($status =~ m/Changes to be committed/) {
        run("git-diff --cached");
        run("git commit -m '$msg'");
    }
    else {
        print "No changes to be committed...\n";
    }
}

sub print_title {
    my $msg = shift;
    print "\n" . ('#' x length($msg)) . "\n$msg\n" . ('#' x length($msg)) . "\n";
}

sub change_branch {
    my $name = shift;

    my $branches = qx(git-branch);
    if ($branches =~ m/^\*?\s+\Q$name\E/m) {
        print "Branch $name already exists ...\n";
    }
    else {
        run("git-branch $name");
    }
    run("git-checkout $name");
}


sub usage {
    die <<EOT;
USAGE: $0 [--tag X] --src Y --dst Z
EOT
}

sub pretify_conflicts {
    my $page_name = shift;
    my $workspace = shift;
    my $text = read_file($page_name);

    my @lines = split /\n/, $text;
    my $in_diff = 0;
    my $out = '';
    for my $l (@lines) {
        $l = ".pre\n<<<<<<< $workspace" if $l =~ m/^<<<<<<< HEAD:.+$/;
        $l = ">>>>>>> $1\n.pre" if $l =~ m/^>>>>>>> ([^:]+):/;
        $out .= "$l\n";
    }
    return $out;
}

# Cases to care about:
# * page doesn't exist in push_to workspace
# * page does exist
