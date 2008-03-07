#!/usr/bin/perl
use strict;
use warnings;
use Socialtext::System qw/shell_run/;
use Socialtext::File qw/get_contents set_contents/;
use Sys::Hostname qw/hostname/;

my $Hostname = hostname();
my $Config = {
    dashboard_user => "dashboard\@$Hostname",
    dashboard_pass => "dashboard",
};

unless ($< == 0) {
    die "Must be run by root!\n";
}

my $APT_SOURCES = '/etc/apt/sources.list';
my $apt = get_contents($APT_SOURCES);
unless ($apt =~ m/tps-dashboard/) {
    print "Adding tps-dashboard to $APT_SOURCES\n";
    $apt .= <<EOT;
deb https://apt.socialtext.net/socialtext tps-dashboard main alien
EOT
    set_contents($APT_SOURCES, $apt);
}

shell_run("apt-get update");
shell_run("apt-get install libsocialtext-server-dashboard-perl");

# Create the dashboard rester user
my $ST_ADMIN = "sudo -u www-data st-admin";
shell_run("-$ST_ADMIN create-user "
          . "--email $Config->{dashboard_user} "
          . "--password '$Config->{dashboard_pass}' ");

# Create Rester config file
my $RESTER_CONF = '/etc/socialtext/dashboard-rester.conf';
set_contents($RESTER_CONF, <<EOT);
server = http://$Hostname
username = $Config->{dashboard_user}
password = $Config->{dashboard_pass}
workspace = dashboard-admin
EOT

print "Create the dashboard-admin workspace and add the rester user\n";
shell_run("-$ST_ADMIN create-workspace --name dashboard-admin --title "
          . "'Dashboard Admin'");
shell_run("-$ST_ADMIN add-member --email $Config->{dashboard_user} "
          . "--workspace dashboard-admin");

print "Hook the dashboard-admin workspace up to auto-generate the\n",
      "dashboard when it is changed.\n";
shell_run("-$ST_ADMIN set-ping-uris --workspace dashboard-admin "
          . "http://$Hostname/webplugin/cgi/dashboard/update.cgi");

print "Creating a test dashboard template\n";
require Socialtext::Resting::Getopt;
my $r = Socialtext::Resting::Getopt::get_rester('rester-config' => $RESTER_CONF);
$r->put_page('Dashboard Template', <<EOT);
.pre
<html>
<head><title>Test</title></head>
<body>Test</body>
</html>
.pre
EOT

print "Checking for dashboard HTML to be created\n";
my $HTML = '/var/www/socialtext/dashboard/index.html';
while (!-e $HTML) {
    print '.';
    sleep 1;
}
print "\nHTML exists!  yay\n";

$r->put_page('Announcements and Links', <<EOT);
This page explains how the dashboard page is wired together.

The overall page template comes from the [Dashboard Template] page, and uses content from these areas:

* *XXX FILL ME IN!*

When any page in these workspaces change, the dashboard will be updated a few seconds later.
EOT

shell_run("/etc/init.d/apache2 restart");
print "Done, go visit http://$Hostname\n";
