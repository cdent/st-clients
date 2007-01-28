#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Socialtext::Resting;
use lib 'lib';
use Socialtext::PeopleDirectory;

my $rester = Socialtext::Resting->new(    
    username => 'user@example.com',
    password => 'password',
    server => 'http://localhost:21000/',    
    workspace => 'admin',
);

my $pd = Socialtext::PeopleDirectory->new(rester => $rester);
print "Updating people directory:\n\n" . $pd->generate_directory;
