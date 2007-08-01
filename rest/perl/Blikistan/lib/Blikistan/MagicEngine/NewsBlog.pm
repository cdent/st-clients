package Blikistan::MagicEngine::NewsBlog;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use URI::Escape;
use JSON;
use DateTime;
use Net::OpenID::Consumer;

sub print_blog {
    my $self = shift;
    my $r = $self->{rester};

    my $params = $self->load_config($r);
    $params->{rester} = $r;
    $params->{blog_tag} ||= $self->{blog_tag};
    $self->{blog_tag} = $params->{blog_tag};

    my @recent_posts = $self->get_recent_posts($r);

    $params->{recent_items} = [
	map {
		title => $_,
		uri => _linkify($r, $_),
	    }, @recent_posts,
	];

    my $return;
    if ( $self->{single_post} ) {
	$return = $self->print_post($r, $params, $self->{single_post});
    } elsif ( ($self->{archive} && $self->{archive} eq 'all') || $self->{search} ) {
	$return = $self->get_page_list($r, $params);
    } elsif ( $self->{comment} ) {
	$return = $self->post_comment($r, $params);
    } else {
	$return = $self->get_blog($r, $params);
    }
    return $return;
}

sub normalize_openid {
    my $self = shift;
    my $openid = shift;

    $openid =~ s/\S+/_/g;
    return $openid;
}

sub post_comment {
    my $self = shift;
    my $r = shift;
    my $params = shift;
    
    my $commenttext = $self->{'comment-text'};
    my $email = $self->{email};
    my $openid = $self->{openid};
    my $request = Apache::Request->instance( Apache->request );

    my $fields = ($openid && $email) ? 1 : 0;
    my $openid_passback = $request->param('openid.mode') ? 1 : 0;

    my $csr = Net::OpenID::Consumer->new(
        ua              => LWP::UserAgent->new,
        args            => $request,
        consumer_secret => 'THIS IS MY SECRET!',
    );

    if ( !$fields && !$openid_passback ) {
	## reject
    }

    # Downhill slope:
    # /news/comments/pagename: set cookie then post the comment we find
    # /news/comments, fields and a cookie, post the comment from the referer
    # store comment or retrieve comment: /tmp/<openid>

    if ( $fields ) {
	if ( $self->_check_cookie ($request, $request->param('openid')) ) {
	    warn "I have a cookie, woo hoo.  I should just post my comment.";
	}
	# First, check for a cookie, post if we have one
	my $uri = $request->uri;
	my ($page_name) = ($ENV{HTTP_REFERER} =~
		m#/news/post/([^\#]*)#);
 	# Store the comment text to a temp file based on 
 	# user's reported openid and the page name
	my $FULL_URI = "http://www.perlfoundation.org/news/comments/$page_name";
	my $BASE_URI = "http://www.perlfoundation.org/news";

	my $claimed_identity = 
		$csr->claimed_identity($request->param('openid'));
	my $check_url = $claimed_identity->check_url(
		return_to => "$FULL_URI",
		trust_root => "$BASE_URI"
	);

        $request->header_out(Location => $check_url);
        $request->status(302);
	$request->send_http_header;
    }
	
    if ( $openid_passback ) { 
	my $claimed_identity = $request->param('openid.identity');
	if ( my $setup_url = $csr->user_setup_url ) {
            $request->header_out(Location => $setup_url);
            $request->status(302);
	    $request->send_http_header;
        } elsif ( $csr->user_cancel ) {
            $request->header_out(Location => $ENV{HTTP_REFERER} );
            $request->status(302);
	    $request->send_http_header;
        } elsif ( my $vident = $csr->verified_identity ) {
            my $verified_url = $vident->url;
            if ( !$self->_set_cookie($request->param('openid.identity') ) ) {
                 return undef;
            }
	    # Retrieve the comment and post it
	}
        $request->header_out(Location => '/' );
        $request->status(302);
	$request->send_http_header;
    } 
}

sub _check_cookie {
    my $self = shift;
    my $request = shift;
    my $claimed_identity = shift;

    my $cookies = Apache::Cookie->fetch;
    my $cookie = $cookies->{'TPF-commenter'};
    return unless $cookie;
    my %user_data = $cookie->value;
    my $mac = _MAC_for_openid ( $claimed_identity );
    unless ( $mac eq $user_data{MAC} ) {
	$request->log_reason( "Invalid MAC predented for $claimed_identity");
	return;
    }
    return $claimed_identity;
}

sub _set_cookie {
    my $self = shift;
    my $claimed_identity = shift;
    $claimed_identity =~ s#/$##g;
    my $value = {
	openid => $claimed_identity,
	MAC    => _MAC_for_openid($claimed_identity),
    };
    my $request = Apache::Request->instance( Apache->request );
    my $cookie = Apache::Cookie->new(
	$request,
	-name    => 'TPF-commenter',
	-value   => $value,
	-expires => '+12M',
	-path    => '/',
    )->bake;
    return $claimed_identity;
}

sub _MAC_for_openid {
    
    return Digest::SHA1::sha1_base64( $_[0], Socialtext::AppConfig->MAC_secret );
}

sub get_recent_posts {
    my $self = shift;
    my $r = shift;
    my @posts = $self->get_json_list($r, 'name');
    @posts = splice @posts, 0, 10;
    return @posts;
} 
	
sub get_blog {
    my $self = shift;
    my $r = shift;
    my $params = shift;
    $params->{title} = "The Perl Foundation";
    my @posts;

    if ( $self->{category} ) {
	my $category = ucfirst($self->{category});
	$category =~ s/\///g;
	@posts = $self->_get_posts_in_category( $r, $self->{category}, @posts );
	$params->{title} = "The Perl Foundation ($category Category)";
	$params->{archive_title} = "$category Archives";
       $params->{about} = "This page contains an archive of all entries posted to The Perl Foundation in the <b>$category</b> category.  They are listed from newest to oldest.";
  	$params->{about_title} = $self->{category} . " Category";
	$params->{index} = "category-archive";
     } elsif ( $self->{archive} ) {
	$self->{archive} =~ s/\///g;
	warn "Archive is " . $self->{archive} . "\n\n\n\n";
        @posts = $self->get_json_list($r, 'name', 'last_edit_time', $self->{archive});
	$params->{index} = "date-based-archive";
	my $pretty_archive = $self->pretty_date($self->{archive});
	$params->{about} = "This page contains all entries posted to The Perl Foundation in <b>$pretty_archive</b>.  They are listed in order from newest to oldest.";
	$params->{about_title} = "$pretty_archive Archive";
	$params->{archive_title} = "$pretty_archive Archives";
     } else {
	@posts = $self->get_recent_posts($r);
 	$params->{index} = "main-index";
     } 

    $params->{posts} = [
        map { 
            title => $_, 
            content => $self->_get_page($r, $_),
	    author => $self->_get_author($r, $_),	    
            uri => _linkify($r, $_),
	    sig_date => $self->_get_sigdate($r, $_),
	    title_date => $self->_get_titledate($r, $_),
	    commentcount => $self->{comments}{$_},
        }, @posts,
    ];

    return $self->render_template( $params );
}

sub pretty_date {
    my $self = shift;
    my ($year, $month) = split (/-/, $_[0]);
    return $self->get_monthname($month) . ", $year";
}

sub get_monthname {
    my $self = shift;
    my $month = shift;
    my @monthname = ("","January","February","March","April","May","June","July","August","September","October","November","December");
    return $monthname[$month];
}

sub get_json_set {
    my $self = shift;
    my $r = shift;

    if ( $self->{json} ) {
	return $self->{json};
    }

    $r->accept("application/json");
    my @page_jsons = $self->get_blog_pages($r);
    $self->{json} = jsonToObj($page_jsons[0]);
    return $self->{json};
}

sub set_json {
    my $self = shift;
    my $r = shift;
    my ($field, $value) = @_;

    my $json_arrayref = $self->get_json_set($r);

    foreach my $page_obj (@$json_arrayref) {
 	$page_obj->{$field} = $value;
    }

    $self->{json} = $json_arrayref;
}

sub get_json_list {
    my $self = shift;
    my $r = shift;
    my ($return_field, $check_field, $string) = @_;
    my $json_arrayref = $self->get_json_set($r);

    my @return;
    my %date;
    foreach my $page_obj (@$json_arrayref) {
	$date{$page_obj->{'name'}} = $page_obj->{'last_edit_time'};
	if (!$page_obj->{'last_edit_time'} ) { warn "No last edit time for $page_obj->{'name'}\n"; }
	if ($check_field && $string) {
	    if ( $check_field eq 'tags') {
		next unless (grep (/$string/i, @{$page_obj->{tags}}) );
	    } else {
                next unless ($page_obj->{$check_field} =~ /\Q$string\E/);
 	    }
	}
	if ( $return_field ne 'object' ) {
        	push (@return, $page_obj->{$return_field});
	} else {
		push (@return, $page_obj);
	}
    }
    @return = sort { ($date{$a} && $date{$b}) ? $date{$b} cmp $date{$a} : 1 } @return;
    return @return;
}
 
sub get_blog_pages {
     my $self = shift;
     my $r = shift;
     my $test;
     unless ( $test = $r->query() ) {
	$r->query("category:$self->{blog_tag}");
     }
     warn "TEST is $test\n\n\n";
     my @posts = $r->get_pages();
     return @posts;
}
 
sub get_page_list {
    my $self = shift;
    my $r = shift;
    my $params = shift;
    $params->{index} = "master-archive-index";
    $params->{title} = "The Perl Foundation Archives";
    $r->accept("text/html");
    my @posts;
    if ( $self->{search} ) {
 	my $query_string = "category:$self->{blog_tag} AND $self->{search}";
	$r->query( $query_string );
        $params->{title} = "Search results for " . $self->{search} . " in The Perl Foundation";
	$r->accept("text/plain");
	@posts = $r->get_pages();
    } else {
	$r->query("category:$self->{blog_tag}");	
	@posts = $self->get_json_list($r, 'name');
    }
    
    $params->{content} = "<ul>";
    foreach my $post (@posts) {
	my $uri = _linkify($r, $post);
	$params->{content} .= "<li><a href=\"$uri\">$post</a></li>";
    }
    $params->{content} .= "</ul>"; 
    return $self->render_template( $params );
}

sub _get_posts_in_category {
    my $self = shift;
    my $r = shift;
    my $category = shift;

    my @posts = $self->get_json_list ($r, 'name', 'tags', $category);
    
    return @posts;
}

sub print_post {
    my $self = shift;
    my $r = shift;
    my $params = shift;
    $params->{post_title} = shift;
    $params->{index} = "individual-entry-archive";
    ($params->{post_title}) ||= $r->gettaggedpages($params->{blog_tag});
    $params->{title} = $params->{post_title} . " (The Perl Foundation)";
    $params->{post} = 
         {
            title => $params->{post_title},
            content => $self->_get_page_with_tags($r, $params->{post_title}),
            author => $self->_get_author($r, $params->{post_title}),
            uri => _linkify($r, $params->{post_title}),
            sig_date => $self->_get_sigdate($r, $params->{post_title}),
	    title_date => $self->_get_titledate($r, $params->{post_title}),
        };
    $params->{about} = "This page contains a single entry from the blog posted on <b>" . $self->_get_titledate($r, $params->{post_title}) . "</b>.";
    $params->{about_title} = $self->{category} . " Category";
    return $self->render_template( $params );
}

sub _linkify {
    my $r = shift;
    my $page = shift;
    $page = uri_escape($page);
    return "/news/post/$page";
}

sub _get_page_with_tags {
 	my $self = shift;
	my $r = shift;
	my $page_name = shift;
	my $content = $self->_get_page($r, $page_name, 1);
	my @tags = $r->get_pagetags($page_name);
	if (@tags) {
	   $content .= "<h4>Tags:</h4>";
	   foreach my $tag (@tags) {
		$tag =~ s/^.*<li>/<li>/g;
		$tag =~ s#'tags/#'/news/category/#g;
		next if ($tag =~ /News|Recent Changes/);
		next unless ($tag =~ /<li>/);
		$content .= $tag . "\n";
	   } 
 	}
	$content .= $self->{comment_text}{$page_name};
        return $content;
}

sub _get_page {
    my $self = shift;
    my $r = shift;
    my $page_name = shift;
    my $full = shift;
    $r->accept('text/html');
    my $html = $r->get_page($page_name) || '';

    while ($html =~ s/<a href="([\w_]+)"\s*/'<a href="' . _linkify($r, $1) . '"'/eg) {}

    $html =~ s#^<div class="wiki">(.+)</div>\s*$#$1#s;
    my @comments = grep ( /<em>contributed by/, split (/<hr \/>/, $html));
    if ( $#comments >= 0 ) {
	warn "I got $#comments for $page_name\n";
    	$self->{comments}{$page_name} = $#comments + 1;
	$html =~ s/(<hr \/>\Q$comments[0]\E.*$)//gs;
	$self->{comment_text}{$page_name} = $1;
    } else {
        $self->{comments}{$page_name} = 0;
    }
    
    return $html;
}

sub _get_author {
    my $self = shift;
    my $r = shift;
    my $page_name = shift;
   
    $r->accept("application/json"); 
    my ($user_info) = $self->get_json_list($r, 'last_editor', 'name', $page_name);
    if (!$user_info) { warn "NO USER FOR $page_name"; return undef }
    my $user_json = $r->get_user($user_info);
    my $user_obj = jsonToObj($user_json);
    if ( $user_obj->{first_name} or $user_obj->{last_name} ) {
        return ($user_obj->{first_name} . " " . $user_obj->{last_name}); 
    } else {
	return $user_info;
    }
}

sub _get_titledate {
    my $self = shift;
    my $r = shift;
    my $page_name = shift;
    my ($date) = $self->get_json_list($r, 'last_edit_time', 'name', $page_name);
    warn "Got $date for $page_name\n";
    my ($year, $month, $day, $hour, $minute, $second) = 
		($date =~ m/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):\d\d GMT/);
    return $self->get_monthname($month) . " $day, $year";
}

sub _get_sigdate {
    my $self = shift;
    my $r = shift;
    my $page_name = shift;
    my ($date) = $self->get_json_list($r, 'last_edit_time', 'name', $page_name);
    my ($year, $month, $day, $hour, $minute, $second) = 
		($date =~ m/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):\d\d GMT/);
    return $self->get_monthname($month) . " $day, $year $hour:$minute";
}
1;

