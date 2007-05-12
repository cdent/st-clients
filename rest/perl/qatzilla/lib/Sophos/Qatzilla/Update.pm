package Sophos::Qatzilla::Update;
use strict;
use warnings;
use CGI qw(:standard escapeHTML);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dump 'dump';
use Template;
use Sophos::Devweb qw(get_title);
use Sophos::Qatzilla::DBAccess qw(get_products 
				  get_product_reports
				  get_test_sections
				  
				  update_test_case
				  get_product 
                                  get_test_case
				  get_test_cases 
				  get_report
				  get_test_section
			         );
use Sophos::Qatzilla::Settings;
use Apache2::Const qw(:common);
use Sophos::Qatzilla::Historical qw(get_class);

sub handler {
    my $r = shift;
    my $q = CGI->new($r);

    my $force      = $q->param("force") || "";
    my $has_conflict = $q->param("conflicts") || "";
    my $template = $has_conflict ? 'update_conflicts.tmpl' : 'update.tmpl';

    my $tmpl_vars;

    # load the template up
    $tmpl_vars->{conflict_table} = process_conflicts($q) if $has_conflict;
    my $section_id = $tmpl_vars->{section_id} = $q->param("section_id"); 
    die "no section_id" unless $section_id;

    my $test_section = get_test_section($section_id);

    my $report_id = $tmpl_vars->{report_id} = $test_section->{report_id};
    my $report = get_report($report_id);

    my $product_id = $tmpl_vars->{product_id} = $report->{product_id};
    my $product = get_product($product_id);

    if(my $filename = $product->{product_xid}) {
	$filename =~ s/\.\.\.$/$test_section->{filename}/;
        $tmpl_vars->{test_filename} = $filename;
    } else {
        $tmpl_vars->{test_filename} = "Unknown";
    }
       
    $tmpl_vars->{header} = get_title(
        title => "Qatzilla Update: " . localtime,
        right => get_links($product_id),
    );

    my $tester = $tmpl_vars->{tester} = cookie('QatzillaUser') || "";
    my $sec_tester = $test_section->{tester} || "";
    $tmpl_vars->{sec_tester} = $sec_tester unless $sec_tester =~ /^multi=/;

    $tmpl_vars->{product_name} = escapeHTML($product->{name});
    $tmpl_vars->{report_name} = escapeHTML($report->{name});
    $tmpl_vars->{section_name} = escapeHTML($test_section->{name});
    $tmpl_vars->{product_id} = $product_id;
    $tmpl_vars->{report_id} = $report_id;

    $tmpl_vars->{products} = get_products();
    $tmpl_vars->{reports} = get_product_reports($product_id);
    $tmpl_vars->{sections} = get_test_sections($report_id, $tester);

    # these ids are mandatory
    my @ids = ($product_id, $report_id, $section_id);
    unless($product_id and $report_id and $section_id) {
        warn "Not all ids are present!";
    }

    # check to see if a button has been pressed
    my $action = $q->param('action');
    if ($action) {
        if ($action eq "Submit" or $action eq "Force") { 
            $force = "on" if $action eq "Force";
            return process_updates($q, $force, @ids);
        }
        elsif ($action eq "Cancel") { 
            my $url = "/qatzilla/summary?report_id=$report_id&product_id=$product_id";
            print redirect(escapeHTML($url));
            return OK;
        }
    }
        
    print header;

    my $test_cases = get_test_cases(@ids) unless $has_conflict;
    $tmpl_vars->{test_cases} = $test_cases;

    $tmpl_vars->{heights} = {};

    foreach (@$test_cases) {
	$tmpl_vars->{heights}{$_->{name}} ||= 0;
	$tmpl_vars->{heights}{$_->{name}}++;
    }

    $tmpl_vars->{escapeHTML} = \&escapeHTML;
    $tmpl_vars->{lc} = sub { lc $_[0] };

    $tmpl_vars->{status_is} = sub {
	my ($a,$b) = map { lc $_ } @_;
	return 1 if $a eq $b;
	return 1 if $a eq 'fail' and $b eq 'blocked';
	return 1 if $b eq 'fail' and $a eq 'blocked';
	return 0;
    };

    my $t = Template->new( INCLUDE_PATH => $config->{WWW_DIR} );
    $t->process($template, $tmpl_vars) or die $t->error;
    return OK;
}


sub process_conflicts {
    my ($q) = @_;
    my $tc_ids = $q->param("tc_ids");
    my @tc_list = split /,/, $tc_ids;
    
    my $conflict_table = <<EOF;
    <table class="qatzilla">
	<tr>
	    <td class="tableHeader">Test Case</td>
	    <td class="tableHeader">Platform</td>
	    <td class="tableHeader">Old Status</td>
	    <td class="tableHeader">New Status</td>
	    <td class="tableHeader">Old Comment</td>
	    <td class="tableHeader">New Comment</td>
	</tr>
EOF

    foreach my $tc_id (@tc_list) {
	my $tc = get_test_case($tc_id);
	my $new_status = $q->param("blocked_$tc_id") ? 'Blocked' : escapeHTML($q->param("status_$tc_id"));
	my $new_comment = escapeHTML($q->param("comment_$tc_id"));
	$tc->{name} = escapeHTML($tc->{name});
	$tc->{comment} = escapeHTML($tc->{comment});
	
	# make the name bold if it's a pr test case
	my $boldstart = "";
	my $boldend = "";
	$boldstart = "<b>" if $tc->{tc_xkeys}{pr};
	$boldend = "</b>" if $tc->{tc_xkeys}{pr};
        my $platform = escapeHTML($tc->{os});
	my $old_class = lcfirst $tc->{status};
	my $new_class = lcfirst $new_status;
	#add to the table
	$conflict_table .= <<EOF; 
	<tr>
	<td class="tableContent">$boldstart $tc->{name} $boldend </td>
	<td class="tableContent">$platform</td>
	<td class="$old_class">$tc->{status}</td>
	<td class="$new_class">$new_status</td>
	<td class="tableContent">$tc->{comment}</td>
	<td class="tableContent">$new_comment
	<input type="hidden" name="status_$tc_id" value="$new_status" />
	<input type="hidden" name="comment_$tc_id" value="$new_comment" />
	</td>
        </tr>
EOF
    }

    $conflict_table .= "</table>"
                    . qq(<input type="hidden" name="tc_ids" value="$tc_ids" />);
    return $conflict_table;
}
    
sub process_updates {
    my ($q, $force, $pid, $rid, $sid) = @_;

    warn 'process_updates';

    my @conflicts;
    my $test_cases = get_test_cases($pid, $rid, $sid);
     
    # handle things a bit differently if coming from a conflict case
    my $tc_ids = $q->param("tc_ids") || "";
    if ($tc_ids) {
	# conflicts, only process the given tc_ids
	foreach my $tc_id (split /,/, $tc_ids) {
	    my $status = $q->param("blocked_$tc_id") ? 'Blocked' : $q->param("status_$tc_id");
	    my $comment = $q->param("comment_$tc_id") || "";
	    my $tester = $q->param("tester_$tc_id") || "";
	    warn "update_test_case($tc_id, $status, $comment, $tester)\n";
	    update_test_case($tc_id, $status, $comment, $tester);
	}
	print redirect("/qatzilla/summary?report_id=$rid&product_id=$pid");
	return OK;
    }
    
    foreach my $tc (@$test_cases) {
	my $tc_id = $tc->{tc_id};
	my $new_status = param("blocked_$tc_id") ? 'Blocked' : param("status_$tc_id");
	my $new_comment = param("comment_$tc_id") || "";
	my $new_tester = param("tester_$tc_id") || "";
	$tc->{comment} ||= "";
	$tc->{tester} ||= "";

	# skip if nothing has changed
        next if $new_status eq $tc->{status} and 
                $new_comment eq $tc->{comment} and
		$new_tester eq $tc->{tester};
	    
	#check for conflicts
	if ($new_status ne $tc->{status} and 
            $tc->{status} ne "Untested" and !$force) {
	    # old status value wasn't Untested. Requires a force.
	    push @conflicts, { tc_id => $tc_id, 
                               status => $new_status, 
                               comment => $new_comment,
                               tester => $new_tester,
                             };
	    next;
	}

	# now, set values in DB to new values.  TODO: Add user

	my $status = $q->param("blocked_$tc_id") ? 'Blocked' : $q->param("status_$tc_id");
	warn "Changing status of $tc_id to $status";
	update_test_case($tc_id, 
			 $status,
                         $q->param("comment_$tc_id"),
		         $q->param("tester_$tc_id"));
    }
    
    # process conflicts here    
    if (@conflicts) {
	# we have conflicts. prepare a redirect url
	my $conflict_url = "/qatzilla/update?report_id=$rid&product_id=$pid"
                           . "&section_id=$sid&conflicts=1";
	my $conflict_tc_ids = "";
	foreach my $c (@conflicts) {
	    my $tc_id = $c->{tc_id};
	    $conflict_tc_ids .= "$tc_id,";
	    $conflict_url .= "&status_$tc_id=$c->{status}"
                             . "&comment_$tc_id=$c->{comment}"
			     . "&tester_$tc_id=$c->{tester}";
	}
	$conflict_url .= "&tc_ids=$conflict_tc_ids";
	print redirect($conflict_url);
	return OK;
    }

    print redirect("/qatzilla/summary?report_id=$rid&product_id=$pid");
    return OK;
}

1;
