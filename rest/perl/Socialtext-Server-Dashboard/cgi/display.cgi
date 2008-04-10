#!/usr/bin/perl                                                                 
use strict;                                                                     
use warnings;                                                                   
use Socialtext::CGI::User qw/get_current_user/;                                 
use CGI qw/redirect header/;

unless (get_current_user()) {
    print redirect('/nlw/login.html?redirect_to=%2F');                          
    exit;                                                                       
}

print header();
    
local $/ = undef;                                                               
my $dashboard_html = '/var/www/socialtext/dashboard/index.html';                
open(my $fh, $dashboard_html) or die "Couldn't open $dashboard_html: $!";       
print <$fh>;
close $fh;

exit;
