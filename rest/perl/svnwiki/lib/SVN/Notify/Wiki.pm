package SVN::Notify::Wiki;
use strict;
use warnings;
use SVN::Notify ();
use SVN::SVNLook;
use Socialtext::Resting::Getopt qw/get_rester/;
use Data::Dumper;

our @ISA = qw(SVN::Notify);
our $VERSION = '0.01';

sub prepare {
    my $self = shift;
    $self->prepare_recipients;
}

sub execute {
    my ($self) = @_;
    my $rev = $self->{revision};
    my $svnlook = SVN::SVNLook->new(
        repo => $self->{repos_path},
        cmd => $self->{svnlook},
    );

    my ($author,$date,$logmessage) = $svnlook->info($rev);
    chomp $logmessage;
    our ($added, $deleted, $modified) = $svnlook->fileschanged($rev);
    my %diffs = $svnlook->diff($rev);

    my $repo = _short_repo_name($self->{repos_path});
    my $page_name = "$repo - r$self->{revision}";
    my $branch = $self->_branch_prefix || 'trunk';
    my @tags = ('revision', $author, $branch, $repo);
    my $page = <<EOT;
^^ r$self->{revision} - $author, $date
*Comment:*
.pre
$logmessage
.pre

^^ Files Changed
EOT
    for my $type (qw/added deleted modified/) {
        $page .= "^^^ " . ucfirst($type) . "\n";
        no strict 'refs';
        for my $file (@{ $$type }) {
            $page .= "* $file\n";
	    (my $filename = $file) =~ s#.+/##;
	    $file =~ s/\//_/g;
            push @tags, $file, $filename;
        }
    }

    $page .= "\n^^ Diff\n";
    for my $file (keys %diffs) {
        $page .= "^^^ `$file`\n.pre\n$diffs{$file}\n.pre\n\n";
    }

    my $r = get_rester('rester-config' => $self->{to});
    die "no server" unless $r->server;

    $| = 1;
    print "Putting page $page_name ... ";
    $r->put_page($page_name, $page);
    for (grep { length } @tags) {
        print "($_), ";
        $r->put_pagetag($page_name, $_);
    }
    print "\n";
}

sub _branch_prefix {
    my $self       = shift;
    my $svnlook    = $self->svnlook;
    my $repos_path = $self->repos_path;
    my $revision   = $self->revision;

    my @branches_mentioned = $self->_branches_mentioned;

    # If the change affects only one branch, say its name.
    return
        @branches_mentioned == 1 && $branches_mentioned[0] ne 'trunk'
        ? "$branches_mentioned[0] "
        : '';
}

# Returns a list of all the branches mentioned in the current change.
sub _branches_mentioned {
    my ( $self ) = @_;
    my $svnlook    = $self->svnlook;
    my $repos_path = $self->repos_path;
    my $revision   = $self->revision;

    open my $look_fd, "$svnlook dirs-changed -r $revision $repos_path |";

    my %changes;
    while (<$look_fd>) {
        if ( defined( my $branch = _branch_for_dir($_) ) ) {
            ++$changes{$branch};
        }
    }
    close $look_fd;

    return keys %changes;
}

# Given a directory, return
#   'trunk' if it's on the trunk,
#   the branch name if it's on if it's on a branch,
#   undef otherwise.
sub _branch_for_dir {
    local ($_) = @_;
    return m{^(trunk)/} || m{^(?:private-)?branches/(.+?)/} ? $1 : undef;
}

# Returns a suitable short name for the repo.
sub _short_repo_name {
    local ($_) = @_;

    return m{^/var/svn\.wikiwyg\.net/code}
        ? 'wikiwyg'
        : (m{/([^/]+)/?$})[0];
}


1;
