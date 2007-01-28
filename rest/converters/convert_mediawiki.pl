#!/usr/bin/perl

use Parse::MediaWikiDump;
use Encode;

$source = @ARGV[0];

$pages = Parse::MediaWikiDump::Pages->new($source);

my $dir = "RHIO-output";
if (-d $dir) {
	unlink $dir;
}

mkdir ($dir);
chdir ($dir);

while (defined($page = $pages->next)) {
	next if ($page->title =~ /^Image:/);
	next unless ($page->username);
	my $page_id = name_to_id($page->title);
	mkdir ($page_id);
	my $timestamp = $page->timestamp;
	$timestamp =~ s/\D//g;

	open (FILE, ">:utf8", "$page_id/$timestamp.txt");
	if ($page->categories) {
	    while (my $category = pop(@{$page->categories})) {
		print FILE "Category: $category\n";
	    }
	}
	print FILE "Encoding: utf8\n\n";
	my $text = $page->text ;
	my $print = Encode::decode_utf8($$text);
	my @lines = split (/\n/, $print);
	foreach my $line (@lines) {
		$line = convert_markup($line);
		print FILE $line . "\n";
	}
	close(FILE);
	symlink ("$timestamp.txt", "$page_id/index.txt");
	print "Title '", $page->title, "' id ", $page->id, "\n";
}

sub convert_markup {
	my $line = shift;
 	# [[<stuff>]]        == [<stuff>]
	# == stuff here ==   == ^^ stuff here
	 
	# ''''' is bold italic
	$line =~ s/'''''(.*?)'''''/*_$1_*/g;

   	# ''' is bold
	$line =~ s/'''(.*?)'''/*$1*/g;

        # '' is italic
        $line =~ s/''(.*?)''/_$1_/g;

	# [[<stuff>]] is [<stuff>]
	$line =~ s/\[\[([^\]]*)\]\]/[$1]/g;

	# Headers
	$line =~ s/^=([^=].*)=$/^ $1/g;
	$line =~ s/^==([^=].*)==$/^^ $1/g;
	$line =~ s/^===([^=].*)===$/^^^ $1/g;
	$line =~ s/^====([^=].*)====$/^^^^ $1/g;

	# Links
	$line =~ s#\[(http://\S+) ([^\]]*)\]#"$2"<$1>#g;
	$line =~ s#\[(.*?)\|(.*?)]#"$2"[$1]#g;
	$line =~ s#<br>\s*$##g;

	# Images
	$line =~ s#\[Image:(.*?)\]#{image: $1}#g;
	return $line;
}

sub name_to_id {
    my $id = shift;
    $id = '' if not defined $id;
    $id =~ s/[^\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM]+/_/g;
    $id =~ s/_+/_/g;
    $id =~ s/^_(?=.)//;
    $id =~ s/(?<=.)_$//;
    $id =~ s/^0$/_/;
    $id = lc($id);
}
