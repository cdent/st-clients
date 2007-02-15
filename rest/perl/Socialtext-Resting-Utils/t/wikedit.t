#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

my $script = "bin/wikedit";

my $perl = "$^X -Ilib";
like qx($perl -c $script 2>&1), qr/syntax OK/, "$script compiles ok";

Write_to_file: { SKIP: {
    skip "needs wikeditrc", 1, unless -e "$ENV{HOME}/.wikeditrc";
    my $file = "t/out.$$";
    END { unlink $file if $file and -e $file }
    unlink $file if -e $file;
    like qx($perl $script -o $file Foo), qr/Wrote Foo content to \Q$file\E/;
} }
