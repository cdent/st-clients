#!/usr/bin/perl

use strict;
use warnings (FATAL => 'all');
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Sophos-Qatzilla',
    VERSION      => '1.000',
    AUTHOR       => 'Sophos PLC',
    ABSTRACT     => 'QA Testing Zyztem',
    clean        => { FILES => '*.ppd *.tar.gz' },
   EXE_FILES    =>  [],
);

use lib "../support/lib";
use MY::ppd_install;
use MY::libscan;
