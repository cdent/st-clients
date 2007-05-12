package Sophos::Qatzilla::Test;
use strict;
use warnings;
use Template;
use CGI qw(:standard);
use Sophos::Devweb qw(get_title);
use Sophos::Qatzilla::DBAccess qw(get_products munge_test_plans munge_text);
use Sophos::Qatzilla::Settings;
use Apache2::Const qw(:common);
use Data::Dumper;
  
sub handler {
    my $r = shift;
    my $q = CGI->new($r);

    print header;

    # set up the template
    my $template_file = "test.tmpl";
    my $template = Template->new( INCLUDE_PATH => $config->{WWW_DIR});
    my $tmpl_vars;

    my $product_id = $q->param('pid');
    my $title = get_title(
        title => "Qatzilla Overview: " . localtime,
        right => get_links($product_id),
    );
    $tmpl_vars->{devweb_title} = $title;

    my $testrest = $q->param('testrest');
    my $tests;
    if ($testrest) {
        $tests = munge_text($testrest);
    }
    elsif ($product_id) { 
        $tests = munge_test_plans($product_id);
    }
    else { # default view
        $tmpl_vars->{products} = get_products();
    }
    $tmpl_vars->{mungedump} = Dumper $tests if $tests;

    # render the page
    $template->process($template_file, $tmpl_vars) or die $template->error();
    return OK;
}

1;
