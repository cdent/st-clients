#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Socialtext::RemotelySimple' );
}

diag( "Testing Socialtext::RemotelySimple $Socialtext::RemotelySimple::VERSION, Perl $], $^X" );
