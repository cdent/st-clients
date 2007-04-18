#!/usr/bin/perl

my $twiki_web = $ARGV[0] or usage();
my $data_dir = "/opt/content/twiki/data/$twiki_web";
my $attach_dir = "/opt/content/twiki/pub/$twiki_web";
my $output_dir = "/tmp/$twiki_web";
my $page_out_dir   = "$output_dir/pages";
my $attach_out_dir = "$output_dir/attach";
system ("rmdir $output_dir; mkdir -p $page_out_dir; mkdir -p $attach_out_dir");

sub usage {
	print "Usage: $0 <twiki_web>\n";
	exit(0);
}

# Retrieve list of pages
chdir ($data_dir);
my @pages = <*>;

foreach my $page (@pages) {
	next unless $page =~ /,v$/;
	chomp $page;
	# Retrieve revision list
	my @revisions = `rlog $page | grep ^revision | cut -c10-13`;
	my $file_name = $page;
	$file_name =~ s/.txt,v//g;
	system ("mkdir $page_out_dir/$file_name");
	my $page_name = "$twiki_web - $file_name";
	foreach my $revision (@revisions) {
		my $content = '';
		chomp $revision;
		my ($author, $date);
		my @content = `co -p -r$revision $page`;
		foreach my $line (@content) {
		    if ($line =~ /TOPICINFO/) {
			($author, $date) = ($line =~
		    	    m/^\%META:TOPICINFO{author="([^"]+)" date="(\d+)"/);
		    }
		    if ($line =~ /^\%META:FILEATTACHMENT/) {
			#%META:FILEATTACHMENT{name="EWT_USGAAP_Userguide.pdf" attr="h" comment="" date="1137159621" path="O:\WORK\PDF\EWT_USGAAP_Userguide.pdf" size="278915" user="CamillM" version="1.1"}%
		    }
		    next if ($line =~ /^\%META/);
	  	    $line = convert_wikitext($line);
		    $content .= $line;
		}
		open (FILE, ">$page_out_dir/$file_name/$revision");
		print FILE $content;
		open (META, ">>$page_out_dir/$file_name/meta");
		print META "$revision : $page_name : $file_name : $author : $date";
	}
} 

sub convert_wikitext {
	my $line = shift;
	$line =~ s/^-+\+!?!?[^\+]/^ /;
	$line =~ s/^-+\+\+!?!?[^\+]/^^ /;
	$line =~ s/^-+\+\+\+!?!?[^\+]/^^^ /;
	$line =~ s/^-+\+\+\+\+!?!?[^\+]/^^^^ /;
	$line =~ s/^-+\+\+\+\+\+!?!?[^\+]/^^^^^ /;

	if ( $line =~ /People\.[A-Z]/) {
	   $line =~ s/People.([A-Z][a-z]+[A-Z]+\w+)(\W)/[$1]$2/;
	} else {
	    $line =~ s/\b([A-Z]+[a-z]+[A-Z]+\w+)\b/[$1]/;
        }
	$line =~ s#</?no?p>##g;
	$line =~ s#</?b>#*#g;
	$line =~ s#</?i>#_#g;
	$line =~ s/<br ?\/>//;

	# [[ATOM.Purpose][ *Purpose* ]]
	$line =~ s#\[\[([^\.]+)\.([^\]]+)\]\[([^\]]+)\]\]#\Q{link $1 [$2]}\E#;

	# [[ATOM][ *New Functions* ]
	$line =~ s/\[\[([^\]]+)\]\[([^\]]+)\]\]/{link [$2]}/;

	if ($line =~ /<a href/) {
	    my ($uri, $name) = ($line =~ /<a href="([^"]+)">(.*)<\/a>/);
	    my $clean_uri = clean_uri($uri);
	    my $clean_name = clean_name($name);
	    my $replacement;
  	    if ($clean_uri eq $clean_name) {
	       $replacement = $uri;
	    } else {
		$replacement = '"' . $name . '"<' . $uri . '>';
	    }
	    $line =~ s/\Q<a href="$uri">$name<\/a>\E/\Q$replacement\E/g;     	
	}
	
	# Bullets
	if ($line =~ /^\s*\*/) {
	    my $space_count;
	    my $tab_count;
	    my ($leading) = ($line =~ /^(\s+)\S/);
	    $leading =~ s/\t/$tab_count++; /eg;
	    my $replace = '*' x $tab_count;
	    $line =~ s/^\s+\* /$replace /g;
	}
	return $line;
}

sub clean_uri {
    my $uri = shift;
    $uri =~ s#^\w+://##g;
    $uri =~ s#\\#/#g;
    $uri =~ s#%20# #g;
    return $uri;
}

sub clean_name {
    my $name = shift;
    $name =~ s#^(\w+:|)//##g;
    $name =~ s#\\#/#g;
    return $name;
}
