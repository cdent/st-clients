package Blikistan::MagicEngine::PerlSite;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use URI::Escape;
use JSON;

sub print_blog {
	my $self = shift;
	my $r = $self->{rester};

 	$self->{config_page} = "Site Config";
        $self->{template_page} = "Site Template";
	my $params = $self->load_config($r);
	my $rewrite = Socialtext::WikiObject::YAML->new(
			page => "Rewrite Map",
			rester => $r,
			)->as_hash;

	$params->{rester} = $r;
	$params->{blog_tag} ||= $self->{blog_tag};
	warn "Blog tag is " . $params->{blog_tag} . "\n";
	$params->{base_uri} ||= '/hydra';
        $params->{nav_page} = 'navigation';
        $params->{start_page} = 'the_perl_foundation';

	my $page = $self->{subpage} || $params->{start_page};

# Need to get the metadata here
	$r->accept('application/json');
       warn "Going to get page for $page now\n";
	my $return = _get_page($r, $page);
	if ($return =~ /not found/) {
		if ($page = _redirect_uri($page, $rewrite)) {
		    return;
		}
		$r->accept('text/html');
		$params->{nav} = _get_page ($r,
					    $params->{nav_page},
					    '','');
		$params->{page} = _get_page ($r,
					     "Page Not Found",
					     '','');
		return $self->render_template($params);
	}
	my $page_obj = jsonToObj($return);
	my $page_name = $page_obj->{name};
	my $page_uri = $page_obj->{page_uri};
	
	$r->accept('text/html');
	my $nav  = _get_page($r, 
			$params->{nav_page},
			$params->{base_uri},
			$page_uri);

	my ($page_content);
	if ( $self->{search} ) {
		$page_content = _search($r, 
				$self->{search},
				$params->{base_uri},
				'search');
	} elsif ( $self->{tag} ) {
		warn "I have a tag!\n";
		$page_content = _tag($r, $self->{tag}, $params->{base_uri}, 'tag');
	} elsif ( $self->{attachment} ) {
		warn "Trying for $self->{attachment} on $self->{page} now\n";
		$r->accept("application/json");
		my $attach_json = $r->get_page_attachments( $self->{page} );
		my $attach_objs = jsonToObj($attach_json);
		foreach my $attachment ( @$attach_objs ) {
		    next unless ($attachment->{name} eq $self->{attachment});
		    my $content_type = $attachment->{"content-type"};
		    my $content_id = $attachment->{"id"};
		    $self->{request}->content_type( $content_type );
		    $self->{request}->status_line("201 OK");
		    $self->{request}->send_http_header;
		    my $attach_content = 
		 	$r->get_pageattachment( $self->{page}, $content_id, $self->{attachment} );
		    $self->{request}->print( $attach_content );
		    return;
		}	    
	} else {
		$page_content = _get_page($r, 
				$page,
				$params->{base_uri},
				$page_uri);
		$page_content = "<h1>$page_name</h1>\n$page_content";
	}

	$params->{nav} = $nav;
	$params->{page} = $page_content;	
	return $self->render_template( $params );
}

sub _fix_links {
    my $r = shift;
    my $base_uri = shift;
    my $page_uri = shift;
    my $page_content = shift;
    my $return;

    $base_uri =~ s#/hydra##g;
    # Interesting pieces of the page URI
    my ($server_uri, $workspace, $page_name) = 
	($page_uri =~ m#(https?://[^/]+)/([^/]+)/.*\?(.*)$#);

    # Now we can build the internal REST links
    my $rest_page_uri = "/data/workspaces/$workspace/pages/";
    my $rest_tag_uri  = "/data/workspaces/$workspace/tags";
    my @links = ($page_content =~ m/href=["']([^'"]+)["']/g);

    foreach my $link (@links) {
	if ( $link =~ m#^[^/]+$# ) {
		$page_content =~ s/href=(.)$link/href=$1$base_uri$link/g;
	} elsif ( $link =~ m/^$rest_tag_uri/ ) {
		$page_content =~ s#$rest_tag_uri/([^\/]+)/pages#/tag/$1#g;
	} elsif ( $link =~ m/^$rest_page_uri/ ) {
		$page_content =~ s/$rest_page_uri/$base_uri/g;
	} elsif ( $link =~ m/^[\.\/]*pages/ ) {
		$page_content =~ s/href=.*pages\//href='$base_uri/g;
	}
    }

    my %seen;
    my @image_links = ($page_content =~ m/src=["']([^'"]+)["']/g);
    foreach my $link (@image_links) {
	next if $seen{$link}++;
	if ( $link =~ m/attachments/ ) {
		$page_content =~ s/$link/$server_uri\/$link/g;
	}
	else {
		warn "$link has no attachments\n";
	}
    }
    return $page_content;
}

sub _redirect_uri {
	my $page = shift;
	my $rewrite = shift;

	warn "Heading through rewrites for $page now\n";
	my @rewrites = keys %$rewrite;
	my $original = $page;
	foreach my $key (reverse sort @rewrites) {
		$page =~ s#^$key.*$#$$rewrite{$key}#g;
		warn "I got $page after $key\n";
		last if ($original ne $page);
	}
	if ($original ne $page) {
		my $app = Socialtext::WebApp->NewForNLW;
		$app->redirect("/$page");			
		return 1;
	}	
}

sub _tag {
    my $r = shift;
    my $tag = shift;
    my $base_uri = shift;
    my $page_uri = shift;
    $r->accept('text/html'); 
    my $return = $r->get_taggedpages($tag);
    $return = _fix_links ($r,
                        $base_uri,
                        $page_uri,
                        $return);
    return $return;
}

sub _search {
    my $r = shift;
    my $query_string = shift;
    my $base_uri = shift;
    my $page_uri = shift;
    $r->accept('text/html'); 
    $r->query($query_string);
    my $return = $r->get_pages();
    $return = _fix_links ($r,
                        $base_uri,
                        $page_uri,
                        $return);
    return $return;
}
    
sub _get_page {
    my $r = shift;
    my $page_name = shift;
    my $base_uri = shift;
    my $page_uri = shift;
    my $html = $r->get_page($page_name) || '';

    $html =~ s#^<div class="wiki">(.+)</div>\s*$#$1#s;
    $html = _fix_links ($r,
			$base_uri,
			$page_uri,
			$html);
    return $html;
}

1;

