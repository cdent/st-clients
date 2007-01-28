package Socialtext::RemotelySimple;

use strict;
use warnings;
use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;

our $VERSION = '0.1';

=head1 NAME

Socialtext::RemotelySimple - A simple and experimental interface to pages in a Socialtext workspace

=head1 SYNOPSIS

    my $content =
        Socialtext::RemotelySimple::getPage(\%ConnectionInfo, $pageName);

=head1 DESCRIPTION

This modules provides a simple method for performing GET and POST 
requests over HTTP to a Socialtext workspace. It interacts with 
the L<Socialtext::Lite> interface. It was written to demonstrate how 
easy it can be to interact with a Socialtext workspace outside a 
browser.

The module is not yet feature complete.

The distribution includes a sample script C<socialtexter> that uses
the module to provide a text based interface to editing pages.

=cut

my $WORD = '\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM';
my $PageBase = 'lite/page';
my $LoginURL = 'nlw/submit/login';

=head1 METHODS

The following methods have as their first argument a reference to 
a hash containing information about the user connecting to the 
workspace. The structure is as follows:

=over 4

=item username

The username that will authorize to the workspace.

=item password

The password that will be used to authorize. Be aware of security 
issues here.

=item workspace

The id of the workspace that is being accessed.

=item server

The base URL of the server where the workspace is located.

=item cookie

The session cookie of an already authenticated user.

=back

When making a request, if the cookie field is not set, the other
information is used to authenticate the user.

=head2 getPage(\%userInfo, $pageName)

Retrieves the wikitext content of a page with the name $pageName,
or the empty string if the page does not exist.

=cut
sub getPage {
    my $userInfo = shift;
    my $pageName = shift;

    _doLogin($userInfo) unless $userInfo->{cookie};

    my $url = _pageURL($userInfo, $pageName);
    
    my $response = eval {
        _makeRequest(
            accept  => 'text/plain',
            method   => 'get',
            url      => $url,
            userinfo => $userInfo,
        );
    };
    die $@ if $@;

    # REVIEW: risky but something needs to catch auth failure
    if ($response->content =~/Log in to Socialtext/) {
        die "username, password, or cookie incorrect.\n" .
            "Reset username and password.\n";
    }

    return $response->content;
}

=head2 savePage(\%userInfo, $pageName, $content)

Replace the wikitext content of a page with the name $pageName,
with $content. No effort is made to manage contention. This
$content will overwrite.

=cut
sub savePage {
    my $userInfo = shift;
    my $pageName = shift;
    my $content  = shift;

    _doLogin($userInfo) unless $userInfo->{cookie};

    my $url = _pageURL($userInfo, $pageName);

    my $response = eval {
        _makeRequest(
            method   => 'post',
            url      => $url,
            userinfo => $userInfo,
            form     => {
                page_body => $content,
                subject   => $pageName,
            },
        );
    };
    die $@ if $@;

    # REVIEW: risky but something needs to catch auth failure
    if ($response->content =~/Log in to Socialtext/) {
        die "username, password, or cookie incorrect.\n" .
            "Reset username and password.\n";
    }
}

=head2 deletePage(\%userInfo, $pageName)

Delete (but not purge) the page with name $pageName. Die if
there is an error.

=cut
sub deletePage {
    my $userInfo = shift;
    my $pageName = shift;

    _doLogin($userInfo) unless $userInfo->{cookie};

    my $url = _pageURL( $userInfo, $pageName );

    my $response = eval {
        _makeRequest(
            method   => 'delete',
            url      => $url,
            userinfo => $userInfo,
        );
    };
    die $@ if $@;

    # REVIEW: risky but something needs to catch auth failure
    if ($response->content =~/Log in to Socialtext/) {
        die "username, password, or cookie incorrect.\n" .
            "Reset username and password.\n";
    }

    # if the operate was success on the _makeRequest() side
    # the page was deleted
    return 1;
}

sub _pageURL {
    my $userInfo = shift;
    my $pageName = shift;

    return $userInfo->{server}
        . $PageBase . '/'
        . $userInfo->{workspace} . '/'
        . _toID($pageName);
}

sub _toID {
    my $id = shift;
    $id = '' if not defined $id;
    $id =~ s/[^$WORD]+/_/g;
    $id =~ s/_+/_/g;
    $id =~ s/^_(?=.)//;
    $id =~ s/(?<=.)_$//;
    $id =~ s/^0$/_/;
    $id = lc($id);
    return URI::Escape::uri_escape($id);
}

sub _doLogin {
    my $userInfo = shift;

    my $response = eval {
        _makeRequest(
            method => 'post',
            url    => $userInfo->{server} . $LoginURL,
            form   => {
                username => $userInfo->{username},
                password => $userInfo->{password},
            },
        );
    };
    die $@ if $@;

    my @cookies = $response->header('Set-Cookie');
    foreach my $cookie (@cookies) {
        $cookie =~ s/;.*$//;
    }
    die "unable to auth, try again\n" unless @cookies;
    $userInfo->{cookie} = join(';', @cookies);
}


sub _makeRequest {
    my %p = @_;

    my $ua = LWP::UserAgent->new();

    $ua->default_header( 'Accept', $p{accept} ) if $p{accept};
    $ua->default_header( 'Cookie', $p{userinfo}->{cookie} )
        if $p{userinfo}->{cookie};
    my $method = $p{method};
    my $response;

    # LWP does not have good support for delete so
    # we need to get more cumbersome for it
    if ($method eq 'delete') {
        $response = _doDelete($ua, $p{url})
    }
    else {
        if ($p{form}) {
            $response = $ua->$method($p{url}, $p{form});
        }
        else {
            $response = $ua->$method($p{url});
        }
    }

    return $response if ($response->is_success or $response->is_redirect);
    die $response->status_line;
}

sub _doDelete {
    my $ua = shift;
    my $url = shift;

    # FIXME: this may not be working. do tests.
    my $request = HTTP::Request->new( 'DELETE', $url );
    return $ua->request($request);
}

=head1 AUTHOR

Chris Dent C<< <chris.dent@socialtext.com> >>
Socialtext, Inc. C<< <code@socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Socialtext, Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

