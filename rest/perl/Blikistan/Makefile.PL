#!/usr/bin/perl -w
use warnings;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Blikistan',
    VERSION_FROM => 'lib/Blikistan.pm',
    PREREQ_PRINT => 1,
    'PREREQ_PM' => {
        'Test::More'                 => '0.42',
        'Socialtext::Resting::Utils' => '0.11',
        'Socialtext::Resting'        => '0.20',
        'Template'                   => 0,
        'HTML::Scrubber'             => 0,
    },
    ABSTRACT => 'Generate static pages based on wiki content',
    AUTHOR   => 'Luke Closs <luke@socialtext.com>',

);
