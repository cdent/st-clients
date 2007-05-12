package Sophos::Qatzilla::Settings;
use strict;
use warnings;
use CGI qw(:standard);
use CGI::Cookie;
use ActiveState::Config::Simple qw(config_parse_file);
use Config;
use Exporter;
our @ISA = ('Exporter');
our @EXPORT = qw($config $settings check_config send_cookies get_links);

our $config;
our $settings;
update_settings();
parse_config();

##################################################################

sub parse_config {
    my $config_file = $ENV{QATZILLA_CONFIG} || "$Config{prefix}/etc/qatzilla.conf";
    die "Cannot find config file $config_file!\n" if !-e $config_file;
    $config = config_parse_file($config_file);

    # some other calculated config values
    $config->{TEMP_DIR} = "$Config{prefix}/tmp";
    $config->{WWW_DIR} = "$Config{prefix}/var/www/devweb/qatzilla";
}

sub check_config {
    foreach my $val (@_) {
	die "required value doesn't exist in config file: \"$val\"\n"
	    unless (defined ($config->{$val}));
    }
}

sub get_links {
    my $product_id = shift || '';

    return { Admin => '/qatzilla/admin',
	     Overview => "/qatzilla?product_id=$product_id",
	     "Rest Test" => '/qatzilla/test',
           };
}
    
sub update_settings {
    # parse cookies into a better format
    my %cookies = fetch CGI::Cookie;
    
    # extract values from cookies
    my @report_platforms = split /,/, $cookies{report_platforms}->value
	if $cookies{report_platforms} and $cookies{report_platforms}->value;
   
    my @historical_platforms = split /,/, $cookies{historical_platforms}->value
	if $cookies{historical_platforms} and 
           $cookies{historical_platforms}->value;

    my $product_id = $cookies{product_id}->value if $cookies{product_id};
    my $number = $cookies{number}->value if $cookies{number};
    my $user = $cookies{user}->value if $cookies{user};
   
    # put values into settings hashref
    foreach my $r_plat (@report_platforms) {
	$settings->{report_platforms}{$r_plat} = 'checked="checked"';
    }

    foreach my $hist_plat (@historical_platforms) {
	$settings->{historical_platforms}{$hist_plat} = 'checked="checked"';
    }

    $settings->{product_id} = $product_id || ""; 
    $settings->{number} = $number || 31;
    $settings->{user} = $user || "";
}

sub send_cookies {
    my ($report_platforms, $product_id, $number, $historical_platforms,
	$user) = @_;

    my $report_platforms_cookie = cookie(
	-name    => 'report_platforms',
	-value   => $report_platforms,
	-expires => '+30y',
    );

    my $product_id_cookie = cookie(
	-name    => 'product_id',
	-value   => $product_id,
	-expires => '+30y',
    );
    
    my $number_cookie = cookie(
	-name    => 'number',
	-value   => $number,
	-expires => '+30y',
    );

    my $historical_platforms_cookie = cookie(
	-name    => 'historical_platforms',
	-value   => $historical_platforms,
	-expires => '+30y',
    );

    my $user_cookie = cookie(
	-name    => 'user',
	-value   => $user,
	-expires => '+30y'
    );

    # send the cookies to the user, refresh
    print header(
	-cookie => [$report_platforms_cookie, $product_id_cookie,
	$number_cookie, $historical_platforms_cookie, $user_cookie]
    );

    my $referrer = param("referrer") || "/qatzilla";
    $referrer =~ tr/;/&/;
    print qq(<meta http-equiv='refresh' content='0;url=$referrer'>);
    print start_html, "Submitted..", end_html;   
}
    
1;
