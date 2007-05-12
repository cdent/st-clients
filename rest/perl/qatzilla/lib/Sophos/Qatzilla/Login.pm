package Sophos::Qatzilla::Login;

use strict;
use warnings;

use Apache2::Const qw(:common);
use CGI qw(:standard escapeHTML);
use CGI::Carp qw(fatalsToBrowser);
use Template;

use Sophos::Devweb qw(get_title);
use Sophos::Qatzilla::Settings;
use Sophos::Qatzilla::DBAccess qw(get_testers);

return 1;

sub handler {
    my $r = shift;
    my $q = CGI->new($r);

    print header;

    # set up the template
    my $template_file = "login.tmpl";
    my $template = Template->new( INCLUDE_PATH => $config->{WWW_DIR});
    my $tmpl_vars;

    $tmpl_vars->{devweb_title} = get_title(
        title => "Qatzilla Overview: " . localtime,
        right => get_links(),
    );

    $tmpl_vars->{users} = get_testers();

    unless ($template->process($template_file, $tmpl_vars)) {
	print $template->error();
	return SERVER_ERROR;
    }
    return OK;
}
