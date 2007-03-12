#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'App::Wikrad';
    use_ok 'App::Wikrad::Window';
    use_ok 'App::Wikrad::PageViewer';
    use_ok 'App::Wikrad::Listbox';
}
