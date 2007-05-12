package Sophos::Qatzilla::TestSection;

use strict;
use warnings;

use Apache2::Const qw(:common);
use CGI qw(:standard escapeHTML);
use CGI::Carp qw(fatalsToBrowser);

use Sophos::Qatzilla::Settings;
use Sophos::Qatzilla::DBAccess qw(get_product
                                  get_test_section 
				  get_test_case
				  get_report);

return 1;

sub handler {
    my $r = shift;
    my $q = CGI->new($r);

    print header('text/plain');

    eval {
	my $tc_id = $q->param('tc_id');

	my ($case,$sid);
	if ($tc_id) {
	    $case = get_test_case($tc_id);
	    $sid = $case->{section_id};
	}
	else {
	    $sid = $q->param('section_id');
	}

	die "section_id or tc_id required" unless $sid;
	
	my $section = get_test_section($sid) || die "No section with section_id $sid\n";

	my $pid = $case ? $case->{product_id} : get_report($section->{report_id})->{product_id};

	my $product = get_product($pid) || die "No product with id $pid\n";

	my $xid = $case->{tc_xid} if $case;
	my $filename = $product->{product_xid};
	die "no filename for section $sid" unless $section->{filename};
	$filename =~ s/\.\.\.$/$section->{filename}/;

	open my $fh, "p4 print $filename |" or die "Couldn't run p4: $!";

	if ($case) {
	    my ($seen_nam, $seen_xid) = @_;
	    while (<$fh>) {
		chomp;
		$seen_xid = $1 =~ /^\s*$case->{tc_xid}\s*$/, next if /^\.\. tc_xid=(.*)/;
		$seen_nam = $1 =~ /^\s*$case->{name}\s*$/, next if /^\.\. tc_name=(.*)/;
		$seen_xid = $seen_nam = 0, next if /^\./;
		next unless $seen_nam and $seen_xid;

		print "$_\n";
	    }
	}
	else {
	    print while <$fh>;
	}

	close $fh or die "Couldn't close p4: $!";
    };
    if ($@) {
	print $@;
	return OK;
    }

    return OK;
}
