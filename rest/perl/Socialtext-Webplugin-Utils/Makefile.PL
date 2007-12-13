#!/usr/bin/perl -w
use warnings;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Socialtext::Server::Dashboard',
    VERSION      => '0.01',
    PREREQ_PM => {
        'Blikistan'                  => '0.07',
        'Socialtext::Resting::Utils' => '0.16',
        'Socialtext::Resting'        => '0.20',
    },
    EXE_FILES => [
        'bin/st-create-server-dashboard',
    ],
    ABSTRACT => 'Scripts to create a server dashboard',
    AUTHOR   => 'Luke Closs <luke@socialtext.com>',
);
