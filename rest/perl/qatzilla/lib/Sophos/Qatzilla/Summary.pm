package Sophos::Qatzilla::Summary;
use strict;
use warnings;
use Template;
use CGI qw(:standard escapeHTML);
use CGI::Cookie; 
use CGI::Carp qw(fatalsToBrowser);
use Data::Dump 'dump';
use Sophos::Devweb qw(get_title);
use Sophos::Qatzilla::DBAccess qw(get_products 
				  get_product_reports
				  set_priority
				  get_counted_sections 
                                  get_report
      		                  set_section_tester
				  get_testers
				  latest_report
				 );
use Sophos::Qatzilla::Settings;
use Sophos::Qatzilla::Historical qw(get_class get_counts get_pclass);
use Sophos::Devweb::Config qw(%dwconfig);
use Apache2::Const qw(:common);

sub handler {
    my $r = shift;
    $r->content_type('text/html');

    my $q = CGI->new($r);
    my %cookies = CGI::Cookie->fetch;
    my $action = $q->param("action") || "";
    my $report_id  = $q->param("report_id");

    my $report = get_report($report_id);
    my $product_id = $q->param('product_id') || $report->{product_id};
    my $tester_filter = $cookies{QatzillaUser} ? $cookies{QatzillaUser}->value : 'all';
    my $force = $q->param("force");

    if ($report_id eq 'latest') {
	my ($latest) = latest_report;
	return $q->redirect("summary?report_id=$latest");
    }

    my $found;
    for my $param ($q->param) {
	my $value = $q->param($param);

	my ($id,$old);

	if (($id,$old) = $param =~ /^section_(\d+):(.*)$/) {
	    if ($value ne $old) {
		set_section_tester($id, $value);
		warn "set tester for $id to $value\n";
		$found = 1;
	    }
	}
	elsif (($id,$old) = $param =~ /^pty_(\d+):(.*)$/) {
	    my $value = $q->param($param);
	    if ($value ne $old) {
		warn "set priority for $id to $value\n";
		set_priority($id,$value);
		$found = 1;
	    }
	}
    }
    return $q->redirect("summary?report_id=$report_id") if $found;

    # set up template
    my $template = Template->new( INCLUDE_PATH => $config->{WWW_DIR});
    my $template_file;

    $template_file =  'summary.tmpl';

    # fill in variables for the header
    my $title = get_title(
        title => "Qatzilla Report Summary: " . localtime,
        right => get_links($product_id),
    );

    my $products = get_products();
    my $product_name = "Unknown Product";
    my ($product) = grep { $_->{product_id} == $product_id } @$products;

    (my $p4_path = $product->{product_xid}) =~ s{/\.\.\.$}{};
    
    my $tester_exists = 0;

    my $tmpl_vars = {
	products => $products,
	reports => get_product_reports($product_id),

        devweb_title => $title,
        p4_path => $p4_path,    
        report_name => escapeHTML($report->{name}),
        product_name => escapeHTML($product->{name}),
        report_id => $report_id,
        product_id => $product_id,

        tester_filter => $tester_filter,
        testers => [ grep {!/^multi=/}@{get_testers($report_id)} ],
        get_class => \&get_class,
        get_pclass => \&get_pclass,
        get_counts => \&get_counts,
	sections => get_counted_sections($report_id, $tester_filter),

	priorities => [qw(highest high medium low)],

        percent => \&percent,
        tester_list => \&tester_list,
        fixup_comment => \&fixup_comment,

	tester_filter => $tester_filter,
	selected_tester => sub { 
	   my $user = shift;
	   return $user eq $tester_filter ? "selected='true'" : "";
	},
    };

    use Data::Dump 'dump';
    open my $fh, ">/tmp/tmpl_vars" or die "error: $!";
    print $fh dump($tmpl_vars);
    close $fh;

    $template->process($template_file, $tmpl_vars) or die $template->error();
    return OK;
}

sub percent {
    my $a = shift;
    return int( 100 * ($a->{pass} + $a->{fail} + $a->{blocked} + $a->{skipped}) / $a->{total})
};

sub tester_list {
    my $tester = shift;
    if ($tester =~ /^multi=(.*)/) {
	return join("<br/>",split(",",$1));
    }
    return undef;
};

sub fixup_comment {
    my $comment = shift || return "";
    $comment = escapeHTML($comment);
    my $bugurl = "$dwconfig{bugs_url}/show_bug.cgi";
    $comment =~ s{(http://\S+)}{<a href="$1">$1</a>}g;
    $comment =~ s{d=(\d+)}{<a href="$bugurl?id=$1">d=$1</a>}g;
    $comment =~ s{\n}{<br/>}g;
    return $comment;
};
	    
1;
