package Apache2::Const;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(OK SERVER_ERROR);
our %EXPORT_TAGS = (
    common => [qw(OK SERVER_ERROR)],
);

sub OK { return 200 }
sub SERVER_ERROR { return 500 }

return 1;
