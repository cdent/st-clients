package Sophos::Qatzilla::Admin;
use strict;
use warnings;
use Template;
use CGI qw(:standard escapeHTML :cgi-lib);
use CGI::Carp qw(fatalsToBrowser);
use URI::Escape;
use Sophos::Devweb qw(get_title);
use Sophos::Qatzilla::DBAccess qw(add_product add_report 
				  get_recent_reports 
				  delete_report get_product
				  get_products
				  get_product_reports
				  copy_report
				  get_product_id_by_name delete_product);
use Sophos::Qatzilla::Settings;
use Apache2::Const qw(:common);

sub handler {
    my $r = shift;
    my $q = CGI->new($r);

    # set up the template
    my $title = get_title(
        title => "Qatzilla Admin: " . localtime,
        right => get_links(),
    );
    my $tmpl_vars = { devweb_title => $title,
                      warnings => '',
                      notice => '',
                    };

    my $action = $q->param('action') || "";
    $tmpl_vars->{action} = $action;
    return create_product_page($q, $tmpl_vars) if $action eq "Create Product";
    return create_report_page($q, $tmpl_vars) if $action eq "Create Report";
    return delete_product_page($q, $tmpl_vars) if $action eq "Delete Product";
    return delete_report_page($q, $tmpl_vars) if $action eq "Delete Report";
    return copy_data_page($q, $tmpl_vars) if $action eq "Copy Data";
    main_page($q,$tmpl_vars);
    return OK;
}

sub main_page {
    my ($q,$tmpl_vars) = @_;

    $tmpl_vars->{products} = get_products(); 
    $tmpl_vars->{warnings} =~ s/\n/<br \/>\n/gm;

    if ($tmpl_vars->{product_id} = $q->param('product_id')) {
	$tmpl_vars->{reports} = get_product_reports($tmpl_vars->{product_id});
    }
    
    print header;
    my $template_file = "admin.tmpl";
    my $template = Template->new( INCLUDE_PATH => $config->{WWW_DIR} );
    $template->process($template_file, $tmpl_vars) or die $template->error();
    return OK;
}

sub create_report_page {
    my ($q, $vars) = @_;

    my $product_id = $q->param('product') 
        or $vars->{warnings} .= "Create Report Failed - No product chosen!";

    my $name = $q->param('new_rep_name') || "";
    $vars->{warnings} .= "Name not set! " unless $name;
   
    # check for problems with input
    return main_page($q,$vars) if $vars->{warnings};
    
    my $report_id;
    eval { 
        $report_id = add_report($product_id, $name);
    };
    if ($@) {
	warn $@;
        $vars->{warnings} .= "Create Report Failed - $@! ";
        return main_page($q,$vars);
    }
    # no warnings, go to next page
    print redirect("/qatzilla/summary?product_id=$product_id&report_id=$report_id");
    return OK;
}

sub create_product_page {
    my ($q, $vars) = @_;

    # get parameters
    my $name = $q->param('new_prod_name');
    unless ($name) {
        $vars->{warnings} .= "Create Product failed - Name not set!\n";
    }
    my $product_xid = $q->param('product_xid');
    if (!$product_xid or $product_xid eq "//depot/") { 
	$vars->{warnings} .= "Create Product failed - Location not set!\n";
    }    
    
    unless ($vars->{warnings}) {
        eval {
	    add_product($product_xid, $name);
	    print redirect("/qatzilla/admin?new_product=" . uri_escape($name));
            return;
        };
	warn $@ if $@;
        $vars->{warnings} .= "Create Product failed - $@" if $@;
    }
    $vars->{notice} .= "Product \"$name\" created.\n" unless $vars->{warnings};
    main_page($q,$vars);
}

sub delete_report_page {
    my ($q, $vars) = @_;

    my $report_id = $q->param('report_id');
    delete_report($report_id);
    $vars->{notice} = "Deleted $report_id OK";
    main_page($q,$vars);
}

sub delete_product_page {
    my ($q, $vars) = @_;

    my $product_id;
    if (my $prod_name = $q->param('prod_name')) {
        $product_id = get_product_id_by_name($prod_name);
    }
    else {
        $product_id = $q->param('product') 
            or $vars->{warnings} .= "Delete Product failed - No product chosen!\n";
    }
    unless ($product_id) {
        $vars->{warnings} .= "Can't delete product - no product_id specified!\n";
        return main_page($q,$vars);
    }

    my $product = get_product($product_id);
    unless ($product) {
        $vars->{warnings} .= "Can't delete product $product_id - it doesn't exist!\n";
        return main_page($q,$vars);
    }
    my $product_name = $product->{name};
    # test to see if there are reports

    my $force = $q->param('force');
    my $reports = get_recent_reports($product_id, 1, 0);
    if (@$reports and !$force) {
	$vars->{warnings} .= "Delete Product failed - "
             . "There are still reports associated with this product!\n";
    }
    
    if (!$vars->{warnings} or $force) {
        eval{
            delete_product($product_id);
	    print redirect("/qatzilla/admin?delete_product=$product_name");
	    return;
        };
	warn $@ if $@;
        $vars->{warnings} .= "Delete Product failed - $@!\n" if $@;
    }
    $vars->{notice} = "Deleted $product_name OK";
    main_page($q,$vars);
}

sub copy_data_page {
    my ($q, $vars) = @_;

    my $from = $q->param('report_from');
    my $to = $q->param('report_to');

    if ($from == $to) {
	$vars->{warnings} .= "The report $from is equal to report $to\n";
    }

    unless ($vars->{warnings}) {
	copy_report($from,$to);
    }

    main_page($q,$vars);
}

1;
