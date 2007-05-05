package Socialtext::WikiCache::Util;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw(get_contents set_contents);

sub set_contents {
    my $file = shift;
    my $content = shift;

    my $fh;
    open $fh, ">", $file or Carp::confess( "unable to open $file for writing: $!" );
    binmode($fh, ':utf8');
    print $fh $content;
    close $fh or die "Can't write $file: $!";

    warn "Wrote $file\n";
    return $file;
}

sub get_contents {
    my $file = shift;

    my $fh;
    open $fh, '<', $file or Carp::confess( "unable to open $file: $!" );
    binmode($fh, ':utf8');

    if (wantarray) {
        my @contents = <$fh>;
        close $fh;
        return @contents;
    }

    my $contents = do { local $/; <$fh> };
    close $fh;
    return $contents;
}

1;
