package Socialtext::WikiObject::IterationPlan;
use strict;
use warnings;
use base 'Socialtext::WikiObject';
use Data::Dumper;

=head1 NAME

Socialtext::WikiObject::IterationPlan - parse out stories and tasks

=cut

our $VERSION = '0.01';

sub _add_whitespace {
    my $self = shift;
    
    my $table_ref = $self->_table_ref;

    return unless @$table_ref;

    if (@{ $table_ref->[-1] }) {
        push @$table_ref, [];
    }
}

# overridden to not smoosh tables together into one giant table
sub _add_table_row {
    my $self = shift;
    my $line = shift;

    my @cols = split /\s*\|\s*/, $line;
    my $table_ref = $self->_table_ref;
    if (@$table_ref) {
        push @{ $table_ref->[-1] }, \@cols;
    }
    else {
        push @$table_ref, [ \@cols ];
    }
}

sub _table_ref { 
    my $self = shift;
    $self->{table} ||= [];
    return $self->{table};
}

=head2 update_estimates

Parse out estimated and actual hours, and attempt to update the Totals
row with updated values.

=cut

sub update_estimates {
    my $self = shift;

    my @tables = (@{ $self->{table} });
    my @table_data;
    for my $t (@tables) {
        my $header = shift @$t;

        my %row_index = _find_row_indexes($header);
        next unless defined $row_index{estimate};
        my %sums;
        for my $row (@$t) {
            next if $row->[0] =~ /total/i;
            my $estimate = $row->[$row_index{estimate}];
            $sums{estimate} += _parse_time($estimate);
            my $actual = $row->[$row_index{actual}];
            $sums{actual} += _parse_time($actual);
        }
        push @table_data, {
            estimate_row => $row_index{estimate},
            estimate => "$sums{estimate}h",
            actual_row => $row_index{actual},
            actual => "$sums{actual}h",
            num_cols => scalar(@$header),
        };
    }

    my $page_content = $self->{rester}->get_page($self->{page});
    my $new_content = '';
    my $table_number = 0;
    my $in_table = 0;
    for my $line (split "\n", $page_content) {
        my $new_line = $line;
        if ($line =~ /^\|/) { # found a table
            if ($line =~ /^\|\s*\*?totals?\*?\s*\|/i) {
                my $cur_data = $table_data[$table_number];
                my @new_row;
                $new_row[$_] = '' for 0 .. $cur_data->{num_cols}-1;
                $new_row[0] = '*Totals*';
                for my $foo (qw(estimate actual)) {
                    my $total = "*$cur_data->{$foo}*";
                    $new_row[$cur_data->{"${foo}_row"}] = $total;
                }
                $new_line = '| ' . join(' | ', @new_row) . ' |';
                warn "new_line: $new_line" if $self->{dryrun};
            }
            $in_table++;
        }
        else {
            if ($in_table) {
                $table_number++;
                $in_table = 0;
            }
        }
        $new_content .= "$new_line\n";
    }

    my $summary_data = "^ Iteration Summary\n" 
                       . $self->_calc_summary(\@table_data);
    $new_content =~ s/^\^ Iteration Summary.+(\^ Stories)/$1/ms;
    $new_content =~ s/^(\^ Stories)/$summary_data\n$1/m;

    warn $new_content;
    $self->{rester}->put_page($self->{page}, $new_content) 
        unless $self->{dryrun};
}

sub _calc_summary {
    my $self = shift;
    my $data = shift;

    my $estimated_hours = 0;
    my $actual_hours = 0;
    for my $table (@$data) {
        (my $est = $table->{estimate}) =~ s/h$//;
        $estimated_hours += $est;
        (my $act = $table->{actual}) =~ s/h$//;
        $actual_hours += $act;
    }
    return <<EOT;

Total estimated hours: ${estimated_hours}h
Total actual hours: ${actual_hours}h
EOT
}

sub _parse_time {
    my $field = shift || '';
    my $hours = 0;
    while ($field =~ /(\d+(?:\.\d+)?)p?h/g) {
        $hours += $1;
    }
    return $hours;
}

sub _finish_parse {
    my $self = shift;
    $self->SUPER::_finish_parse();

    if (@{ $self->{table} } and @{ $self->{table}[-1] } == 0) {
        pop @{ $self->{table} };
    }
}

sub _find_row_indexes {
    my $row = shift;
    my %index;
    my $col = 0;
    for (@$row) {
        (my $heading = $_) =~ s/^\*?(\w+)\*?$/lc($1)/e;
        $index{$heading} = $col;
        $col++;
    }
    return %index;
}

1;
