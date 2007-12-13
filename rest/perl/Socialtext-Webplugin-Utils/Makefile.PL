#!/usr/bin/perl -w
use warnings;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Socialtext::Webplugin::Utils',
    VERSION      => '0.01',
    PREREQ_PM => {
        'Socialtext::Resting::Utils' => '0.16',
        'Socialtext::Resting'        => '0.20',
    },
    ABSTRACT => 'Little server side webplugin helper scripts',
    AUTHOR   => 'Luke Closs <luke@socialtext.com>',
);
