#!/usr/bin/perl
use strict;
use warnings;
use CGI qw/header/;
use Socialtext::Resting::Getopt qw/get_rester/;              
use lib 'lib';
use FindBin;
use Blikistan;
                                                             
my $r = get_rester( 'rester-config' => "$FindBin::Bin/.blog-rester" ); 

my $blikistan = Blikistan->new( 
    rester => $r,
    magic_engine => 'jemplate',
    magic_opts => {
        template_name => 'templates/jblog.tmpl',
    },
);
print $blikistan->print_blog;
