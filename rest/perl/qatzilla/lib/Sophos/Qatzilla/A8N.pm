package Sophos::Qatzilla::A8N;
use strict;
use warnings;
use Template;
use CGI qw(:standard escapeHTML);
use CGI::Cookie; 
use CGI::Carp qw(fatalsToBrowser);
use Data::Dump 'dump';
use Sophos::Devweb qw(get_title);
use Sophos::Qatzilla::DBAccess qw(get_test_cases
                                  get_test_sections
                                  update_test_case
                                );
use Sophos::Qatzilla::Settings;
use Sophos::Devweb::Config qw(%dwconfig);
use Apache2::Const qw(:common);

my %cmd_handlers = (
    tc_list => \&tc_list,
    ts_list => \&ts_list,
    tc_update => \&tc_update,
);

sub handler {
    my $r = shift;
    $r->content_type('text/html');

    my $q = CGI->new($r);
    my $command = $q->param("command") || "";
    if (defined $cmd_handlers{$command}) {
        $cmd_handlers{$command}->($r, $q);        
    } 
    else {
        $r->custom_response(SERVER_ERROR, 
                            "An error occurred: Unrecognized command $command"
                           );
        return SERVER_ERROR;
    }
}

sub error_page { 
    my ($r, $command, $reason) = @_;
    my $error = $command 
                ? "An error occurred executing $command: $reason" 
                : "An error occurred, but I don't know what command failed!";  
    $r->custom_response(SERVER_ERROR, $error);
    return SERVER_ERROR;
}

sub tc_list {
    my ($r,$q) = @_;
    my $report_id  = $q->param('report_id');
    my $product_id = $q->param('product_id');
    my $section_id = $q->param('section_id');
    
    if(!($report_id && $product_id && $section_id)) {
        return error_page($r, 'tc_list', 'missing parameter');
    }

    my $tc_hash = get_test_cases($product_id, $report_id, $section_id); 
    print dump($tc_hash);
    return OK;
}

sub ts_list {
    my ($r,$q) = @_;
    my $report_id  = $q->param('report_id') ||
                     return error_page($r, 'ts_list', 'missing parameter');

    my $ts_hash = get_test_sections($report_id); 
    print dump($ts_hash);
    return OK;
}

sub tc_update {
    my ($r,$q) = @_;
    my @valid_status = qw(Blocked Fail Pass Skipped Untested);
    my $tc_id = $q->param('tc_id');
    my $status = $q->param('status');
    my $comment = $q->param('comment') || '';
    my $tester = $q->param('tester') || 'a8n';

    if (!($tc_id && grep {$_ eq $status} @valid_status )) {
        return error_page($r, 'tc_update', 'missing parameter');
    }
    
    eval {
        update_test_case($tc_id, $status, $comment, $tester);
        print "Test case $tc_id updated to have status $status";
        return OK;
    };
    if ($@) { # in case of transaction failure
        return error_page($r, 'tc_update', 'transaction failure in database');            
    }
}
