#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Mock::LWP;

BEGIN {
    use_ok 'Socialtext::Resting';
}

my %rester_opts = (
    username => 'test-user@example.com',
    password => 'passw0rd',
    server   => 'http://www.socialtext.net',
    workspace => 'st-rest-test',
);

sub new_strutter {
    $Mock_ua->clear;
    $Mock_req->clear;
    $Mock_resp->clear;
    return Socialtext::Resting->new(%rester_opts);
}

Get_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', 'bar');
    is $rester->get_page('Foo'), 'bar';
    result_ok(
        uri  => '/pages/foo',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'text/x.socialtext-wiki' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'etag' ],
        ],
    );
}

Get_page_fails: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', 'no auth');
    $Mock_resp->set_always('code', 403);
    eval { $rester->get_page('Foo') };
    like $@, qr/403: no auth/;
}

Put_new_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 201);
    $rester->put_page('Foo', 'bar');
    result_ok(
        uri  => '/pages/Foo',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/x.socialtext-wiki' ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Put_existing_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    $rester->put_page('Foo', 'bar');
    result_ok(
        uri  => '/pages/Foo',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/x.socialtext-wiki' ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Put_page_fails: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', 'no auth');
    $Mock_resp->set_always('code', 403);
    eval { $rester->put_page('Foo', 'bar') };
    like $@, qr/403: no auth/;
}

Post_attachment: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    local $Test::Mock::HTTP::Response::Headers{location} = 'waa';
    $rester->post_attachment('Foo', 'bar.txt', 'bar', 'text/plain');
    result_ok(
        uri  => '/pages/foo/attachments?name=bar.txt',
        method => 'POST',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/plain' ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'location' ],
        ],
    );
}

Put_tag: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    $rester->put_pagetag('Foo', 'taggy');
    result_ok(
        uri  => '/pages/foo/tags/taggy',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Collision_detection {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 200);
    $Mock_resp->set_always('content', 'bar');
    local $Test::Mock::HTTP::Response::Headers{etag} = '20070118070342';
    $rester->get_page('Foo'); # should store etag
    result_ok(
        uri  => '/pages/foo',
        method => 'GET',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'text/x.socialtext-wiki' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'etag' ],
        ],
    );
    $Mock_resp->set_always('content', 'precondition failed');
    $Mock_resp->set_always('code', 412);
    eval { $rester->put_page('Foo', 'bar') };
    like $@, qr/412: precondition failed/;
    result_ok(
        uri  => '/pages/Foo',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/x.socialtext-wiki' ],
            [ 'header' => 'If-Match', $Test::Mock::HTTP::Response::Headers{etag} ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

exit; 

sub result_ok {
    my %args = (
        method => 'GET',
        ua_calls => [],
        req_calls => [],
        resp_calls => [],
        @_,
    );
    my $expected_uri = "$rester_opts{server}/data/workspaces/"
                       . "$rester_opts{workspace}$args{uri}";
    is_deeply $Mock_req->new_args, 
              ['HTTP::Request', $args{method}, $expected_uri],
              $expected_uri;

    for my $c (@{ $args{ua_calls} }) {
        my ($method, @args) = @$c;
        is_deeply [$Mock_ua->next_call], 
                  [ $method, [ $Mock_ua, @args ]], 
                  "$method - @args";
    }
    is $Mock_ua->next_call, undef;
    for my $c (@{ $args{req_calls} }) {
        my ($method, @args) = @$c;
        is_deeply [$Mock_req->next_call], 
                  [ $method, [ $Mock_ua, @args ]], 
                  "$method - @args";
    }
    is $Mock_req->next_call, undef;
    for my $c (@{ $args{resp_calls} }) {
        my ($method, @args) = @$c;
        is_deeply [$Mock_resp->next_call], 
                  [ $method, [ $Mock_ua, @args ]], 
                  "$method - @args";
    }
    is $Mock_resp->next_call, undef;
}

