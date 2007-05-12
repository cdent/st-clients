package Sophos::Qatzilla::Historical;
use strict;
use warnings;
use Template;
use CGI qw(:standard escapeHTML);
use CGI::Carp qw(fatalsToBrowser);
use Sophos::Devweb qw(get_title);
use Sophos::Qatzilla::DBAccess qw(
				  skip_sections
                                  get_products
                                  get_product_reports
                                  get_product_history
                                 );
use Sophos::Qatzilla::Settings;
use Apache2::Const qw(:common);
use Data::Dump 'dump';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_pclass get_class get_counts);
  
sub handler {
    my $r = shift;

    $r->content_type('text/html');
    my $q = CGI->new($r);

    # set up the template
    my $template_file = "historical.tmpl";
    my $template = Template->new( INCLUDE_PATH => $config->{WWW_DIR});

    my $product_id = $q->param('product_id');
    my $title = get_title(
        title => "Qatzilla Overview: " . localtime,
        right => get_links($product_id),
    );

    if (my @skips = $q->param('skip')) {
	warn "Skipping sections: (@skips)\n";
	skip_sections(@skips);
	print redirect("?product_id=$product_id");
	return OK;
    }

    my $products = get_products();
    my ($product) = grep { $_->{product_id} == $product_id } @$products if $product_id;
    (my $p4_path = $product ? $product->{product_xid} : "") =~ s{/\.\.\.$}{};
    
    my $history = defined $product_id ? get_product_history($product_id) : undef;

    my %timeleft;
    my %timetot;
    while (my ($ts_name,$reports) = each %$history) {
	while (my ($rid,$report) = each %$reports) {
	    $timeleft{$rid} ||= 0;
	    $timetot{$rid} ||= 0;

	    $timetot{$rid} += $report->{time};
	    $timeleft{$rid} += $report->{time} *
			       ($report->{total_untested}/$report->{total});
	}
    }
    $_ = sprintf('%.2f',$_) for (values %timetot, values %timeleft);

    my $reports = defined $product_id ? get_product_reports($product_id) : [];

    for my $r (@$reports) {
	if (my $total = $r->{total} - $r->{total_skipped}) {
	    my $tested = $total - $r->{total_untested};
	    $r->{complete} = sprintf('%.2f',100 * ($tested/$total));
	}
	else {
	    $r->{complete} = 100;
	}
    }

    my $tmpl_vars = {
        devweb_title => $title,
        products => $products,
        product_name => $product ? escapeHTML($product->{name}) : "",
        product_id => $product_id,
        p4_path => $p4_path,
	tester => cookie('QatzillaUser') || undef,
	show_skip => $q->param('show_skip') ? 1 : 0,

        colourize => $q->param('colourize') || 'status',

	blocked => (grep {$_->{total_blocked}} @$reports) ? 1 : 0,

	Dump => sub { warn dump @_ },

	time_left => \%timeleft,
	time_tot => \%timetot,

	reports => $reports,
	history => $history,
	sections => [ $history ? sort keys %$history : () ],

        get_class => \&get_class,
        get_pclass => \&get_pclass,
	get_counts => \&get_counts,
	get_mouseover => \&get_mouseover,

        escapeHTML => \&escapeHTML,
    };

    $template->process($template_file, $tmpl_vars) or die $template->error();
    return OK;
}

sub get_mouseover { 
    my $counts = shift;
    $counts = $counts->[0] if ref $counts eq 'ARRAY';

    return '' unless $counts;

    my $done = $counts->{total_pass} + $counts->{total_fail} + $counts->{total_blocked};
    my $totl = $counts->{total} - $counts->{total_skipped};
    
    my $cplt = $totl ? int($done/$totl*100) : 100;

    return <<EOT;
<table>
    <tr>
	<th>$cplt%</th>
	<td style="border:none">complete</td>
    </tr>
    <tr>
	<th>$counts->{total_pass}/$totl</th>
	<td style="border:none">passed</td>
    </tr>
    <tr>
	<th>$counts->{total_fail}/$totl</th>
	<td style="border:none">failed</td>
    </tr>
    <tr>
	<th>$counts->{total_blocked}/$totl</th>
	<td style="border:none">blocked</td>
    </tr>
</table>
EOT
}

sub get_counts { 
    my $counts = shift;
    $counts = $counts->[0] if ref $counts eq 'ARRAY';

    return '' unless $counts;

    return join ' / ',
	$counts->{total_pass},
	$counts->{total_fail},
	$counts->{total_blocked},
	$counts->{total_skipped},
	$counts->{total};
}

sub get_pclass { 
    my $priority = shift;

    return "blocked" if $priority eq 'highest';
    return "fail" if $priority eq 'high';
    return "skipped" if $priority eq 'medium';
    return "pass" if $priority eq 'low';
    return "qatContent";
} 

sub get_class { 
    my ($pass, $fail, $blocked, $skipped, $total);

    if (@_ == 1) {
        my $counts = shift;
        $counts = $counts->[0] if ref $counts eq 'ARRAY';
    	return "" unless $counts;
        $pass = $counts->{total_pass};
        $fail = $counts->{total_fail};
        $blocked = $counts->{total_blocked};
        $skipped = $counts->{total_skipped};
        $total = $counts->{total};
    }
    else {
        ($pass, $fail, $blocked, $skipped, $total) = @_;
    }

    return "qatContent" unless $total;
    return "blocked" if $blocked > 0;
    return "fail" if $fail > 0;
    return "skipped" if $skipped == $total && $skipped > 0;
    return "pass" if $pass + $skipped == $total;
    return "untested";
} 

1;
