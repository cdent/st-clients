#!/usr/local/bin/perl

use File::Find::Rule;
use File::Basename;
use YAML qw(Dump);
use HTML::WikiConverter::Socialtext;
use Encode;
use URI::Escape;

my $start_dir = $ARGV[0];
my $original_uri = $ARGV[1];
my $workspace = $ARGV[2];
my $subdir = $ARGV[3];

if ( !$workspace ) {
	die "No workspace given, usage: $0 <start_dir> <original_uri> <workspace>\n";
}

my $top_dir = $subdir ? "$start_dir/WikiHome/$subdir" : "$start_dir/WikiHome";
my $top_file = $subdir ? "$start_dir/WikiHome/$subdir.xml" : "$start_dir/WikiHome.xml";

# Files{basename} = fullpath
# Names{basename} = title
# Nodes{basename} = nodenum
# @Comments{nodenum} = (Comment1,Comment2)
my %Files = ();
my %Names = ();
my %Nodes = ();
my %Comments = ();
my %Attribute = ();
my @Comments = ();

if (! -e "$start_dir/WikiHome.xml") {
    die "Usage: $0 <start_dir> \n\tWhere <start_dir> is the top level directory of a Jot XML dump\n";
}

my @files = get_filelist();
convert_content(\@files);
create_wikifiles();
publish_wikifiles();

sub get_filelist {
	my $rule = File::Find::Rule->new;
	$rule->or( $rule->new
	               	->directory
			->name('_revisions')
			->prune
			->discard,
		   $rule->new);
	$rule->name( qr/^.+(.xml)$/ );
	my @files = $rule->in( "$top_dir");
	push (@files, "$top_file");
	return @files;
}

sub convert_content {
	my $files = shift;
	my $fileinfo;
	foreach my $fullpath (@$files) {
		next if ($fullpath =~ /tr\d+(Schema|-)/);
		next if ($fullpath =~ /^tr\d+$/);
		$fileinfo .= gather_info($fullpath);
	}
        open (OUT, ">/tmp/files.yaml");
	print OUT $fileinfo;
}

sub gather_info {
	my $fullpath = shift;
	chomp $fullpath;
        next if ($fullpath =~ /\.\w\w\w\.xml/);
	my ($basename) = fileparse($fullpath);
	if ( $Files{$basename} ) {
		die "2 files with the same filename: $basename\n";
	} 
	$Files{$basename} = $fullpath;
	open FILE, "$fullpath";
	binmode(FILE, ':utf8') ;
	my @content = <FILE>;
	my $content = join ("", @content);
	my $email_comment = ($content =~ /nodeClass="message"/) 
                ? 1 : 0;
	my $comment = ($content =~ /AddPageCommentForm/) 
		? 1 : 0;
        my ($nodes, $properties) = $content =~
                m~^<node ([^>]+)>(.*)~;
        my ($from, $date) = $properties =~
                m~<property name=\"mail/from\" type=\"element\"><html xmlns=\"http://www.w3.org/1999/xhtml\"><p><a href=\"mailto:([^\"]+)\".*<property name=\"mail/sent\" type=\"date\"><date timeZone=\"\w+\">(\w+)</date>~;

	my @array = ($nodes =~ /\w+="[^"]+"/g);
	my %values;
	map { my ($key, $value) = ($_ =~ m/(\w+)="(.*)"/);
		  $values{$key} = $value ;
		  if ($key eq 'nodeClass' && $value eq '"attachment"') {
			$Files{$basename} = undef;
			return;
		  }
		  if ($key eq 'name') {
			$Names{$basename} = $values{$key};
		  }
		  if ($key eq 'nodeId') {
			$Nodes{$basename} = $value;
		  }
		  if ($key eq 'parentNodeId') {
			if ($comment) {
			    push (@{$Comments{$value}}, $fullpath);
			    $Attribute{$fullpath} = "_contributed by {user: $values{user}} at {date: $values{editTime}}_";
			push (@Comments, $basename);	
			$basename =~ s/.xml$//g;
			} elsif ($email_comment) {
                            push (@{$Comments{$value}}, $fullpath);
                            $Attribute{$fullpath} = "_contributed by {user: $from} at {date: $date}_"; 
			push (@Comments, $basename);	
			$basename =~ s/.xml$//g;
                        }
		  }
		} @array;
	return Dump \%values;
}

sub create_wikifiles {
	mkdir ("/tmp/output") unless (-d "/tmp/output");
	chdir ("/tmp/output");
	my $wc = new HTML::WikiConverter( dialect => 'Socialtext');

	foreach my $file (keys %Files) {
		next unless ($Files{$file} =~ /\w/);
		if (grep /\Q$file\E/, @Comments) {
			next;
		}
		open OLD, "$Files{$file}";
		
		my $node = $Nodes{$file};
		my $comments;
	        if ($Comments{$node}) {
		    foreach my $comment_file (@{$Comments{$node}}) {
	  	        open COMMENT, "$comment_file";
		        $comments .= "<hr>";
		        my @comment_lines = <COMMENT>;
			my $comment = join("", @comment_lines);
                        if (grep (/node="message"/, $comment)) {
                            $comment =~ 
                                    s~^.*<property name="main/text" type="element"><html xmlns="http://www.w3.org/1999/xhtml" xmlns:jot="http://www.foopee.com/ns/s3/srvtmpl/">(.*)</html></property>~$1~g;
			    $comments .= $comment;
                        } else {
		            foreach my $line (@comment_lines) {
			        $line =~ 
                                    s/<property name=\"pageComment\/submitted_by\".*\/content>//g;
			        $comments .= $line;
	  	            }
                        }
		        $comments .= "\n" . $Attribute{$comment_file} . "\n";
		    }
		}
	
		my $content = join ("", <OLD>);
		if ($comments) {
			$content .= $comments;
		}
		$file =~ s/\.xml$//g;
		open NEW, ">/tmp/output/$file";
	
		$content =~ s~^.*<property name="main/text" type="element"><html xmlns="http://www.w3.org/1999/xhtml" [^>+]>(.*)</html></property>~$1~g;
		$content =~ s#<property name="sys/permission/email" type="stringList">mailbot</property>##g;
		# Secret rewriting of weird Jot stuff
		$new_content = $wc->html2wiki($content);

		# "Service"<http://kasayka.jot.com/WikiHome/FamilySpace/Signup+Process/Service>
		if ($new_content =~ /$original_uri/) {
			@matches = ($new_content =~ m/("[^"]+"<http:[^>]+>)/g);
			foreach my $match (@matches) {
				my ($page_uri, $url) = ($match =~ m/"([^"]+)"<(http:[^>]+)>/);
				(my $clean_url = $url) =~ s/\+/ /g;
				if ($clean_url =~ /\Q$page_uri\E$/) {
					$new_content =~ s{\Q"$page_uri"<$url>}{[$page_uri]\E};
				}
			}
		}

			
		# "FamilySpace"<wiki:FamilySpace> => [FamilySpace]
		$new_content =~ s/"([^"]+)"<wiki:.*\/\1>/[$1]/g;
	
		# "02 First Run"<wiki:TestFirstRun> => "02 First Run"[TestFirstRun]
		$new_content =~ s/"([^"]+)"<wiki:([^\/>]+)>/"$1"[$2]/g;
	
		# "FamilySpace"<wiki:/WikiHome/FamilySpace> => [FamilySpace]
		$new_content =~ s/"([^"]+)"<wiki:.*\/([^\/>]+)>/"$1"[$2]/g;
	
		# <b><morebold>
		$new_content =~ s/([^\*])\*\*([^\*])/$1*$2/g;
	
		if ($new_content =~ /"<wiki:/) {
			@matches = ($new_content =~ m/("[^"]+"<wiki:[^>]+>)/g);
			foreach my $match (@matches) {
				my ($page_uri, $url) = ($match =~ m/"([^"]+)"<wiki:([^>]+)>/);
				$clean_url = uri_unescape($url);
				if ($clean_url =~ /$page_uri$/) {
					$new_content =~ s/"$page_uri"<wiki:$url>/[$page_uri]/;
				}
			}
		}
		$new_content =~ s/PageCommentForm//g;

		# "Beta Status"<WikiHome/InternalDocs/Beta+Status>
		$new_content =~ s~"([^"]+)"<WikiHome/(.*)/([^\/]+)>$~"$1"[$3]~;
		print NEW $new_content;	
	}
}

sub publish_wikifiles {
	foreach my $file (keys %Names) {
		my $filename = $file;
		$filename =~ s/\.xml$//g;
		if (grep /\Q$filename\E/, @Comments) {
                        next;
                }
		next if ($filename =~ /\.pdf$|\.gif$|\.jpg$|\.png$|\.zip$|\.reg$|\.msg$|\.xls$|\.vsd$|\.htm$|\.mdi$|\.bmp$|\.ppt$|\.doc|\.dtd|^Comment\d+$/i);
		my $strut_cmd = "strut set_page $workspace \"" . $Names{$file} . '" ' . "/tmp/output/$filename";
		print "Command is $strut_cmd\n";
		system("$strut_cmd");
	}
}
