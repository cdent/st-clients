package Sophos::Qatzilla::DBAccess;
use strict;
use warnings;
use DBI;
use DBD::mysql;
use ActiveState::Handy qw(run);
use Sophos::Qatzilla::Settings;
use File::Path qw(mkpath rmtree);
use Sophos::Devweb::Log qw(dwlog);
use Carp qw(croak);
use Sophos::Devweb::Config qw(%dwconfig);
use Data::Dump 'dump';

use Exporter;
our @ISA = qw(Exporter);

# XXX: These can't possibly all be used:
our @EXPORT_OK = qw(add_product
		    add_report
		    update_test_case
		    set_priority
		    get_products
		    get_products_reports
		    get_product_history
		    get_product_reports
		    get_report_summary
		    add_platform
		    get_recent_reports
		    get_test_sections
		    delete_report
		    get_product
		    get_test_case
		    get_test_cases
		    get_report
		    get_test_section
		    get_test_section_summary
		    get_test_section_summaries
		    set_section_tester
		    get_testers
		    skip_sections
		    copy_report
		    update_report_counts
		    get_product_id_by_name
		    delete_product
		    get_external_sections
		    get_section_test_cases
		    delete_test_cases
		    add_test_case
		    munge_test_plans
		    munge_text
		    latest_report
		    get_counted_sections
		   );

# database handle, used by all functions
my $dbh;

chomp(my $p4 = `which p4`);
my $p4user = $dwconfig{p4}{user};
my $p4client = $dwconfig{p4}{client};
my $p4port = $dwconfig{p4}{port};
$p4 = "$p4 -u $p4user -c $p4client -p $p4port";

DB_connect();

sub DB_connect {
    return $dbh if $dbh;
    my $host = $config->{SQL_HOST} || 'localhost';
    $dbh = DBI->connect(
	"DBI:mysql:database=$config->{DATABASE}:$host",
	$config->{USERNAME}, 
	$config->{PASSWORD}, 
	{
	    PrintError => 0,
	    RaiseError => 1,
	},
    ) or die "Can't connect to DB: $DBI::errstr";
}

sub add_product {
    my ($product_xid, $name) = @_;
    
    my $products = get_products();
    foreach my $p (@$products) {
        die "Already a product named $name!\n" if $p->{name} eq $name;
    }

    # prepare the insert statement
    my $sth = $dbh->prepare("INSERT INTO Products VALUES ( NULL, ?, ?)");
    $sth->execute($product_xid, $name);
    my $product_id = $sth->{mysql_insertid};
    $sth->finish();
    return $product_id;  
}

sub add_report {
    my ($product_id, $name) = @_;

    $dbh->begin_work;
    
    # let munge_test_plans do its thing
    my ($change, $tests) = munge_test_plans($product_id);

    warn "Done munging";
    
    # Add this report to the database
    my $sth = $dbh->prepare("INSERT INTO Reports VALUES ( NULL, ?, ?, ?,NULL)");
    $sth->execute($product_id, $name, $change);
    my $report_id = $sth->{mysql_insertid};
    
    # loop through all the data and dispatch out the calls
    foreach my $t (@$tests) {
	warn "Adding test section...";
	#add this test section to the DB
	#_add_test_section will call add_test_cases appropriately.
	_add_test_section($t, $product_id, $report_id);
    }
    $sth->finish();

    $dbh->commit;

    return $report_id;
}

sub update_test_case {
    my ($tc_id, $status, $comment, $tester) = @_;
    
    eval {
        # get previous status, store
        my $sth = $dbh->prepare("SELECT status, report_id, os_id, section_id
                                FROM Test_Cases 
                                WHERE tc_id = ?");
        $sth->execute($tc_id);
        my ($old_status, $rid, $os_id, $sid) = $sth->fetchrow_array();
        
        # update status
        my $update_status_sth = $dbh->prepare("UPDATE Test_Cases 
                                               SET status = ?, comment = ? ,
					       user = ?
                                               WHERE tc_id = ?");
        $update_status_sth->execute($status, $comment, $tester, $tc_id );

        $update_status_sth->finish();

        # decrement previous status count
        my $decrement_sth = $dbh->prepare("UPDATE Counts 
                                           SET count = count - 1
                                           WHERE section_id = ?
                                           AND report_id = ?
                                           AND status = ?");
        $decrement_sth->execute($sid, $rid, $old_status);
        $decrement_sth->finish();
        
        # increment new status count
        my $increment_sth = $dbh->prepare("UPDATE Counts
                                           SET count = count + 1
                                           WHERE section_id = ?
                                           AND report_id = ?
                                           AND status = ?");
        $increment_sth->execute($sid, $rid, $status);

        if ($increment_sth->rows == 0) {
            #no rows affected - need to insert into the Counts table
            my $insert_sth = $dbh->prepare("INSERT INTO Counts
                                         VALUES (?, ?, 9999, ?, 1)");
            $insert_sth->execute($sid, $rid, $status);
            $insert_sth->finish();
        }
        
        $increment_sth->finish();


	# get and set the tester
	my $get_tester_sth = $dbh->prepare("SELECT user
	                                    FROM Test_Cases
	                                    WHERE section_id=?");
	$get_tester_sth->execute($sid);
	my %testers = map {$_->[0] || 'unset' => 1}
		      @{$get_tester_sth->fetchall_arrayref};
	if (keys %testers == 1) {
	    delete $testers{unset};
	}
	if (%testers) {
	    my $new_tester = "multi=" . join(',',keys %testers) if %testers;
	    $get_tester_sth->finish;
	    
	    my $set_tester_sth = $dbh->prepare("UPDATE Test_Sections
						SET tester = ?
						WHERE section_id = ?");
	    $set_tester_sth->execute($new_tester,$sid);
	    $set_tester_sth->finish();
	}
	else {
	    my $set_tester_sth = $dbh->prepare("UPDATE Test_Sections
						SET tester = NULL
						WHERE section_id = ?
						AND tester like 'multi=%'");
	    $set_tester_sth->execute($sid);
	    $set_tester_sth->finish();
	}
    };
    if ($@) {
        # Transaction failed
        $dbh->rollback(); 
        die "Update incomplete: $@! ";
    }
}

sub latest_report {
    my $sth = $dbh->prepare("SELECT report_id FROM Reports ORDER BY report_id DESC LIMIT 1");
    $sth->execute;
    my ($id) = $sth->fetchrow_array();
    $sth->finish();
    return $id;
}

sub get_testers {
    my $report_id = shift || '%';
    my $hide_multi = shift;


    $hide_multi = $hide_multi ? "AND tester NOT LIKE 'multi=%'" : '';

    my $sth = $dbh->prepare("
	SELECT DISTINCT tester 
	FROM Test_Sections 
	WHERE tester IS NOT NULL 
	AND tester != ''
	$hide_multi
	AND report_id like ?
    ");
    $sth->execute($report_id);
    my @testers = map { $_->[0] } @{$sth->fetchall_arrayref};
    $sth->finish;
    return \@testers;
}

sub skip_sections {
    my @sections = @_;

    my $ids = join(',', grep(/^\d+$/, @sections));
    $dbh->do("
	UPDATE Test_Cases 
	SET status = 'Skipped'
	WHERE status = 'Untested'
	AND section_id IN ($ids)
    ");
    update_section_counts($_) for @sections;
}

sub set_section_tester {
    my ($section_id, $tester) = @_;


    my $sth = $dbh->prepare("Update Test_Sections SET tester=? WHERE section_id = ?");
    $sth->execute($tester, $section_id);
    $sth->finish;
}

sub get_products {

    my $sth = $dbh->prepare("SELECT * FROM Products ORDER BY product_id DESC");
    $sth->execute();
    # fetchall_arrayref() gives the data structure we want
    my $product_list = $sth->fetchall_arrayref( { product_id  => 1,
					          product_xid => 1,
					          name        => 1,
					      } );
    $sth->finish();
    return $product_list;
}

sub get_products_reports {

    my $sth = $dbh->prepare("
	SELECT report_id, product_xid, Products.product_id, Reports.name AS report_name, Products.name
	FROM Products LEFT JOIN Reports USING(product_id)
	ORDER BY Products.product_id DESC
    ");
    $sth->execute();
    # fetchall_arrayref() gives the data structure we want

    my %products;
    while (my $row = $sth->fetchrow_hashref) {
	$products{$row->{product_id}} ||= {
	    product_id => $row->{product_id},
	    product_xid => $row->{product_xid},
	    name => $row->{name},
	};
	push @{$products{$row->{product_id}}{reports}}, {
	    report_id => $row->{report_id},
	    name => $row->{report_name},
	} if $row->{report_id};
    }

    $sth->finish();
    return [ sort { $b->{product_id} <=> $a->{product_id} } values %products ];
}

sub get_product {
    my $product_id = shift;

    # get this specific product
    my $sth = $dbh->prepare("SELECT * FROM Products WHERE product_id = ?");
    $sth->execute($product_id);
    my $product = $sth->fetchrow_hashref();
    $sth->finish();
    return $product;  
    
}

sub copy_report {
    my ($from,$to) = @_;
    
    $dbh->do(q{
	UPDATE  Test_Cases AS X, Test_Cases AS Y
	SET     X.comment = Y.comment, 
	        X.status  = Y.status,
		X.user = Y.user
	WHERE	X.report_id = ? AND Y.report_id = ?
	AND	X.tc_xid = Y.tc_xid
	AND	X.os_id = Y.os_id
    }, undef, $to, $from) or die $dbh->errstr;

    $dbh->do(q{
	UPDATE  Test_Sections AS X, Test_Sections AS Y
	SET     X.tester = Y.tester
	WHERE	X.report_id = ? AND Y.report_id = ?
	AND	X.name = Y.name
    }, undef, $to, $from) or die $dbh->errstr;

    update_report_counts($to);
}

sub update_report_counts {
    my $report_id = shift || croak "report_id required";

    # Set counts to 0 initially
    $dbh->do(q{
	UPDATE Counts
	SET   count = 0
	WHERE report_id = ?
    },undef,$report_id);

    my $sth = $dbh->prepare("
	SELECT report_id, section_id, os_id, status, COUNT(*) as count
	FROM Test_Cases
	WHERE report_id = ?
	GROUP BY section_id, os_id, status
    ");
    $sth->execute($report_id);
    while (my $row = $sth->fetchrow_hashref) {
	my $val = $dbh->do(q{
	    UPDATE Counts
	    SET count = ?
	    WHERE Counts.os_id = ?
	    AND   Counts.status = ?
	    AND   Counts.report_id = ?
	    AND   Counts.section_id = ?
	},undef,@$row{qw(count os_id status report_id section_id)});

	if ($val and $val eq '0E0') {
	    $dbh->do(q{
		INSERT INTO Counts
		VALUES (?,?,?,?,?)
	    },undef,@$row{qw(section_id report_id os_id status count)});
	}
    }
    $sth->finish;
}

sub update_section_counts {
    my $section_id = shift || croak "section_id required";

    # Set counts to 0 initially
    $dbh->do(q{
	UPDATE Counts
	SET   count = 0
	WHERE section_id = ?
    },undef,$section_id);

    my $sth = $dbh->prepare("
	SELECT report_id, section_id, status, COUNT(*) as count
	FROM Test_Cases
	WHERE section_id = ?
	GROUP BY section_id, status
    ");
    $sth->execute($section_id);
    while (my $row = $sth->fetchrow_hashref) {
	my $val = $dbh->do(q{
	    UPDATE Counts
	    SET count = ?
	    WHERE Counts.status = ?
	    AND   Counts.report_id = ?
	    AND   Counts.section_id = ?
	},undef,@$row{qw(count status report_id section_id)});

	if ($val and $val eq '0E0') {
	    $dbh->do(q{
		INSERT INTO Counts
		VALUES (?,?,9999,?,?)
	    },undef,@$row{qw(section_id report_id status count)});
	}
    }
    $sth->finish;
}
    
sub get_product_id_by_name {
    my $name = shift;

    # get this specific product
    my $sth = $dbh->prepare("SELECT * FROM Products WHERE name = ?");
    $sth->execute($name);
    my $product = $sth->fetchrow_hashref();
    $sth->finish();
    return $product->{product_id};  
    
}
    
sub get_recent_reports {
    my ($product_id, $num, $offset) = @_;
    $offset ||= 0;

    # if $num is 0, we don't want any limit on the number of rows we return
    # otherwise, fill in the limit statement. We want to insure that it's just
    # a number and doesn't contain things like "; DROP TABLE blah".
    my $limit = "";
    $limit = "LIMIT $num" if $num > 0 and $num =~ /^\d+$/;
    
    # If $offset == 0, which is the most common case, our work is easier,
    # so let's get that out of the way first.
    if ($offset == 0) {
	# no offset, so just get the top $num rows, sorted by date
	my $sth = $dbh->prepare("SELECT * FROM Reports WHERE product_id like ?
						       ORDER BY date
						       DESC $limit ");
	$sth->execute($product_id);
	my $reports = $sth->fetchall_arrayref( { report_id  => 1,
						 product_id => 1,
						 name       => 1,
						 change     => 1,
						 date       => 1
					     } );

	$sth->finish();
	return $reports;						 
    } 
}

sub get_report {
    my $report_id = shift;

    # get this specific product
    my $sth = $dbh->prepare("SELECT * FROM Reports WHERE report_id = ?");
    $sth->execute($report_id);
    my $report = $sth->fetchrow_hashref();
    $sth->finish();
    return $report; 
    
}

sub get_test_section {
    my $section_id = shift;

    # get this test section
    my $sth = $dbh->prepare(<<EOT);
    SELECT * FROM Test_Sections 
    JOIN Reports USING(report_id)
    WHERE section_id = ?
EOT
    $sth->execute($section_id);
    my $test_section = $sth->fetchrow_hashref();
    $sth->finish();
    return $test_section;
}

sub get_product_reports {
    my $product_id = shift;

    # get the relevant test sections
    return $dbh->selectall_arrayref(<<EOT, { Slice => {} }, $product_id);
SELECT Reports.report_id,
       Reports.name,
       FORMAT(SUM(time),2) as time,
       SUM(total_untested) as total_untested,
       SUM(total_pass) as total_pass,
       SUM(total_skipped) as total_skipped,
       SUM(total_fail) as total_fail,
       SUM(total_blocked) as total_blocked,
       SUM(total) as total

FROM Reports
JOIN (
    SELECT report_id,
           SUM(COALESCE(CASE status WHEN 'Untested' THEN count END,0)) AS total_untested,
           SUM(COALESCE(CASE status WHEN 'Pass' THEN count END,0)) AS total_pass,
           SUM(COALESCE(CASE status WHEN 'Skipped' THEN count END,0)) AS total_skipped,
           SUM(COALESCE(CASE status WHEN 'Fail' THEN count END,0)) AS total_fail,
           SUM(COALESCE(CASE status WHEN 'Blocked' THEN count END,0)) AS total_blocked,
	   SUM(count) as total
    FROM Counts
    GROUP BY status, report_id, section_id
) AS X
USING(report_id)

JOIN (
    SELECT report_id, SUM(time) AS time
    FROM Test_Sections
    GROUP BY report_id
) AS Y
USING(report_id)

WHERE product_id = ?
GROUP BY report_id
ORDER BY report_id
EOT
}

sub set_priority {
    my ($section_id,$priority) = @_;

    # get the relevant test sections

    my $sth = $dbh->prepare(<<'EOT');
UPDATE Test_Sections
SET priority = ?
WHERE section_id = ?
EOT
    $sth->execute($priority,$section_id);
    $sth->finish;
}

sub get_counted_sections {
    my ($report_id, $tester) = @_;

    $tester ||= '%';
    $tester =~ s/^all$/%/i;

    # get the relevant test sections
    return $dbh->selectall_arrayref(<<EOT, { Slice => {} }, $report_id, $tester);
SELECT Test_Sections.section_id AS section_id,
       Test_Sections.name AS section_name,
       Test_Sections.tester AS tester,
       Test_Sections.priority AS priority,
       time,
       comment,
       total_untested,
       total_pass,
       total_skipped,
       total_fail,
       total_blocked,
       total

FROM Test_Sections
JOIN (
    SELECT section_id,
           SUM(COALESCE(CASE status WHEN 'Untested' THEN count END,0)) AS total_untested,
           SUM(COALESCE(CASE status WHEN 'Pass' THEN count END,0)) AS total_pass,
           SUM(COALESCE(CASE status WHEN 'Skipped' THEN count END,0)) AS total_skipped,
           SUM(COALESCE(CASE status WHEN 'Fail' THEN count END,0)) AS total_fail,
           SUM(COALESCE(CASE status WHEN 'Blocked' THEN count END,0)) AS total_blocked,
           SUM(count) AS total
    FROM Counts
    WHERE report_id = ?
    GROUP BY section_id
) AS X
USING(section_id)

JOIN (
    SELECT section_id,
	   GROUP_CONCAT(DISTINCT comment SEPARATOR '\\n') AS comment
    FROM Test_Cases
    GROUP BY section_id
) AS Y
USING(section_id)

WHERE tester LIKE ? 
OR    tester LIKE 'multi=\%$tester\%'
OR    tester LIKE 'multi=\%unset\%'
OR    tester IS NULL OR tester = ''

GROUP BY section_id
ORDER BY CASE priority WHEN 'highest' THEN 1 
		       WHEN 'high' THEN 2
		       WHEN 'medium' THEN 3
		       WHEN 'low' THEN 4
		       ELSE 5
		       END,
	 section_name
EOT
}

sub get_product_history {
    my $product_id = shift;


    # get the relevant test sections
    return $dbh->selectall_hashref(<<EOT, [qw(section_name report_id)], {}, $product_id);
SELECT Reports.report_id AS report_id,
       Test_Sections.name AS section_name,
       Test_Sections.section_id AS section_id,
       Test_Sections.priority AS priority,
       time,
       time * (SUM(total_untested) / SUM(total)) as time_left,
       SUM(total_untested) as total_untested,
       SUM(total_pass) as total_pass,
       SUM(total_skipped) as total_skipped,
       SUM(total_fail) as total_fail,
       SUM(total_blocked) as total_blocked,
       SUM(total) as total

FROM Test_Sections 
JOIN Reports
USING(report_id)

JOIN (
    SELECT section_id,
           SUM(COALESCE(CASE status WHEN 'Untested' THEN count END,0)) AS total_untested,
           SUM(COALESCE(CASE status WHEN 'Pass' THEN count END,0)) AS total_pass,
           SUM(COALESCE(CASE status WHEN 'Skipped' THEN count END,0)) AS total_skipped,
           SUM(COALESCE(CASE status WHEN 'Fail' THEN count END,0)) AS total_fail,
           SUM(COALESCE(CASE status WHEN 'Blocked' THEN count END,0)) AS total_blocked,
           SUM(count) AS total
    FROM Counts
    GROUP BY status, section_id
) AS X
ON X.section_id = Test_Sections.section_id
    
WHERE product_id = ?

GROUP BY section_id
EOT
}

sub get_test_cases {
    my ($product_id, $report_id, $sid) = @_;

    # get the relevant test cases
    my $sth = $dbh->prepare("SELECT tc_id, tc_xid, section_id, OS.name AS os,
				    report_id, product_id, status, comment, 
				    user AS tester, tc_xkeys, Test_Cases.name AS name 
				    FROM Test_Cases, OS WHERE product_id = ?
				      AND   report_id  = ?
				      AND   section_id = ?
				    ORDER BY tc_id
			    ");
    $sth->execute($product_id, $report_id, $sid);
					      
    # fetchall_arrayref returns the structure we want
    my $test_cases = $sth->fetchall_arrayref( { tc_id      => 1,
						tc_xid     => 1,
						section_id => 1,
						report_id  => 1,
						product_id => 1,
						status     => 1,
						comment    => 1,
						tester     => 1,
						name       => 1,
						tc_xkeys   => 1,
					    } );
    $sth->finish();		        
    
    # we want to return the tc_xkeys as a hash, making it easier to handle
    foreach my $tc (@$test_cases) {
	next unless $tc->{tc_keys};
	$tc->{tc_keys} =~ tr/[A-Z]/[a-z]/;
	my %tc_xkeys;
	my @tc_xkeys = split (/,/, $tc->{tc_xkeys});
	foreach my $xkey (@tc_xkeys) {
	    $tc_xkeys{$xkey} = 1;
	}
    
	#replace the string version of tc_xkeys with the hash
	$tc->{tc_xkeys} = \%tc_xkeys;
    }
    return $test_cases;
}

sub get_test_case {
    my $tc_id = shift;

    my $sth = $dbh->prepare("SELECT * FROM Test_Cases WHERE tc_id = ?");
    $sth->execute($tc_id);
    my $test_case = $sth->fetchrow_hashref();
    $sth->finish();		        

    $test_case->{os} = 'null operating system';
    
    # we want to return the tc_xkeys as a hash, making it easier to handle
    # we also want all keys to be lowercase
    $test_case->{tc_keys} =~ tr/[A-Z]/[a-z]/ if $test_case->{tc_keys};
    if ($test_case->{tc_xkeys}) {
        my %tc_xkeys;
        my @tc_xkeys = split (/,/, $test_case->{tc_xkeys});
        foreach my $xkey (@tc_xkeys) {
	    $tc_xkeys{$xkey} = 1;
        }
        #replace the string version of tc_xkeys with the hash
        $test_case->{tc_xkeys} = \%tc_xkeys;
    }
    return $test_case;
}

sub get_section_test_cases {
    my $section_id = shift 
        or die "No section_id given to get_section_test_cases";
    
    my $sth = $dbh->prepare("SELECT *, user AS tester FROM Test_Cases
                             WHERE section_id=?
                             GROUP BY tc_xid");
    $sth->execute($section_id);

    # fetchall_arrayref returns the structure we want
    my $test_cases = $sth->fetchall_arrayref( { tc_id      => 1,
						tc_xid     => 1,
						section_id => 1,
						os         => 1,
						report_id  => 1,
						product_id => 1,
						status     => 1,
						comment    => 1,
						tester     => 1,
						name       => 1,
						tc_xkeys   => 1,
					    } );
    
    $sth->finish();
    return $test_cases;
}

sub _add_test_section {         
    my ($t, $pid, $rid) = @_;
    my $section_xid = $t->{section_xid};
    my $name = $t->{name};
    my $test_cases = $t->{test_cases};
    my $filename = $t->{filename};
    my $section_time = $t->{section_time} || 0;

    # add this test section to the DB
    my $sth = $dbh->prepare("
	INSERT INTO Test_Sections (section_xid,report_id,name,filename,time)
	VALUES (?,?,?,?,?)
    ") || die $dbh->errstr;
    $sth->execute($section_xid, $rid, $name, $filename, $section_time);
    my $sid = $sth->{mysql_insertid};
    $sth->finish();		        

    # now go through and add each of the test cases
    foreach my $tc (@$test_cases) {
	add_test_case($tc, $sid, $rid, $pid);
    }
}

sub add_test_case {
    my ($tc, $sid, $rid, $pid) = @_;
    my $tc_xid = $tc->{tc_xid};
    my $name = $tc->{name} || die "No name for tc_xid=$tc->{tc_xid}";
    my $tc_xkeys = $tc->{tc_xkeys};

    eval {
        # add the test case
        my $sth = $dbh->prepare(<<EOT);
INSERT INTO Test_Cases (tc_xid, section_id, os_id, report_id, product_id, name, tc_xkeys)
       VALUES (?, ?, 9999, ?, ?, ?, ?)
EOT
        $sth->execute($tc_xid, $sid, $rid, $pid, $name, $tc_xkeys);
        $sth->finish();		        
        $sth = $dbh->prepare("UPDATE Counts SET count = count + 1
                              WHERE section_id = ?
                              AND report_id = ?
                              AND status = 'Untested'");
        $sth->execute($sid, $rid);

        if ($sth->rows == 0) {
            #no rows affected - need to insert into the Counts table
            my $insert_sth = $dbh->prepare("INSERT INTO Counts
                                            VALUES (?, ?, 9999, 'Untested', 1)");
            $insert_sth->execute($sid, $rid);
        }
    };
    if ($@) {
        die "Error adding test case: $@!";
    }
    return 0;
}

sub delete_product {
    my ($prod_id) = @_;

    $dbh->begin_work;

    my $reports = get_recent_reports($prod_id, 0);
    foreach my $r (@$reports) {
        my $rid = $r->{report_id};
        my $sections = get_test_sections($rid);
        foreach my $s (@$sections) {
            my $sid = $s->{section_id};
            # delete testcases
            my $testcases = get_test_cases($prod_id, $rid, $sid);
            foreach my $t (@$testcases) {
                my $tcid = $t->{tc_id};
                delete_row( table => 'Test_Cases', value => $tcid );
            }

            # delete external sections
            my $ext_sects = get_external_sections($sid);
            foreach my $e (@$ext_sects) {
                delete_row( table => 'External_Sections', value => $e->{tc_id} );
            }

            # delete this section
            delete_row( table => "Test_Sections", value => $sid );
        }
        delete_row( table => "Reports", value => $rid );
    }
    delete_row( table => "Products", value => $prod_id );

    $dbh->commit;
}

sub get_test_sections {
    my $report_id = shift;

    $report_id = latest_report if $report_id eq 'latest';

    my $tester = shift || '%';
    $tester = '%' if $tester eq 'all';

    # get the relevant test sections
    my $sth = $dbh->prepare(<<EOT);
SELECT * FROM Test_Sections 
WHERE report_id = ? 
AND (tester IS NULL OR  tester LIKE ?)
EOT
    $sth->execute($report_id, $tester);
    # fetchall_arrayref returns the structure we want
    my $test_sections = $sth->fetchall_arrayref( { section_id  => 1,
                                                   section_xid => 1,
                                                   report_id   => 1,
                                                   name        => 1,
                                                   tester      => 1,
                                               } );
    $sth->finish();
    return $test_sections;
}

# Deletes test cases with given section / platform
sub delete_test_cases {
    my %opts = @_;

    my $section_id = $opts{section_id} 
        or die "No section_id given to delete_test_cases";
    my $report_id = $opts{report_id}
        or die "No report_id given to delete_test_cases";
    my $platform = $opts{platform}
        or die "No platform given to delete_test_cases";
    
    eval {
        # delete from the Test_Cases table
        my $sth = $dbh->prepare("DELETE FROM Test_Cases
                                 WHERE section_id = ?");
        $sth->execute($section_id);
        $sth->finish();

        # delete any external test sections
        $sth = $dbh->prepare("DELETE FROM External_Sections
                              WHERE section_id = ?");
        $sth->execute($section_id);
        
        # delete from the Counts table
        $sth = $dbh->prepare("DELETE FROM Counts
                              WHERE section_id=?
                              AND report_id=?");
        $sth->execute($section_id, $report_id);
        $sth->finish();

        # now, check to see if any are left. if not, delete the section from
        # the test section table
        $sth = $dbh->prepare("SELECT `count` 
                              FROM Counts 
                              WHERE section_id=?
                              AND report_id=?
                              LIMIT 1");
        $sth->execute($section_id, $report_id);

        my ($exists) = $sth->fetchrow_array();
        $sth->finish();
    
        unless ($exists) {
            # no test cases with this section left - remove it from the
            # test_section table
            $sth = $dbh->prepare("DELETE FROM Test_Sections
                                  WHERE section_id = ?");
            $sth->execute($section_id);
            $sth->finish();
        } 
    };
    if ($@) {
        $dbh->rollback();
        die "Error deleting test cases: $@!";
    }
    return 0;
}

sub delete_row {
    my %opts = @_;

    # valid tables to delete from
    my %tablekeys = (  Products => "product_id", 
		       Reports  => "report_id", 
                       Test_Cases => "tc_id",
                       Test_Sections => 'section_id',
                       External_Sections => 'tc_id',
		       OS       => "os_id");

    # get arguments from hash. 0 / "" / undef values not allowed
    my $table = $opts{table} or die "No table given to delete_row!";
    my $value = $opts{value} or die "No value given to delete_row!";
    
    # make sure this is a valid table
    die "Cannot delete from table $table!" unless exists $tablekeys{$table}; 
    my $key = $tablekeys{$table}; 
    
    my $sth = $dbh->prepare("DELETE FROM $table WHERE $key = ?");
    $sth->execute($value);
    $sth->finish();
}

sub delete_report {
    my $report_id = shift || croak "report_id required";

    $dbh->begin_work;
    delete_row(table => "Reports", value => $report_id);
    $dbh->commit;
}

sub munge_test_plans {
    warn 'munge_test_plans';
    my $product_id = shift;

    # get product information to find report path
    my $product = get_product($product_id) 
	or die "No such product with product_id: $product_id!";
    
    my $path = $product->{product_xid};
    my $tmpdir = "$config->{TEMP_DIR}/qatzilla-$$";
    
    # pre-emptively check for bad p4 locale
    $path =~ m#^(//depot/\S+)/\.\.\.# or 
        die "Not a valid p4 location!";
    my $dir = $1;

    my ($change) = `$p4 changes $dir/... | head -n 1` =~ /Change (\d+)/;
    my $tests;

    my @files = split "\n", `$p4 files $dir/....txt 2>/dev/null`;
    @files = grep { s/#\d+ - .*$// } @files;

    die "No files in $dir" unless @files;
    
    foreach my $file (@files) {
	my $contents = `$p4 print $file`;

	my $test_section = munge_text($contents, 
	                              filename => $file, 
				      prod_dir => $dir
				     );
	# maybe this text file isn't a test plan, we should check
	next unless $test_section->{section_xid};
	push @$tests, $test_section;
    }

    return ($change, $tests);
}
   
sub munge_text {
    my ($contents,%args) = @_;

    my $filename = $args{filename} || die "filename required";
    my $prod_dir = $args{prod_dir} || die "prod_dir required";

    $filename =~ s{^$prod_dir/}{}g;
    my %testsec = ( test_cases => [], filename => $filename );

    # keep track of tc_xids, they have to be unique to a file
    my %tc_xids;
    my @lines = split /\n/, $contents;
    while (@lines) {
	$_ = shift @lines;
        # relevent lines start with ..
        next unless /^\s*\.\./;

        # get the section_xid
        $testsec{section_xid} = $1, next if /section_xid=(\S+)/i;

        # get the name
        $testsec{name} = $1, next if /section_name=(.+\S)/i;

	# get the overall section time
        $testsec{section_time} = $1, next if /section_time=(.+)/i;
        
        # see if we've found a test case
        if (/tc_xid=(\S+)/) {
            my $xid = $1;
            my $tc = {};
            
            # ensure that this tc_xid is unique to the document
            die "Error: duplicate tc_xid $xid in test plan!" 
                if exists $tc_xids{$xid};
            $tc_xids{$xid}++;
            $tc->{tc_xid} = $xid;
            
            # fill in testcase details
            while (@lines) {
                $_ = shift @lines;
                $tc->{name} = $1, next if /tc_name=([\S\s]+\S)/i;
                $tc->{tc_xkeys} = $1, next if /tc_xkeys=([\S\s]+\S)/i;
                last if !/\.\./;      
            }
            
            # add it to the list
            push @{$testsec{test_cases}}, $tc;
        }
    }
    return \%testsec;
}

1;
