use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SVN::Notify::Wiki',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/SVN/Notify/Wiki.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting::Utils' => '0.04',
        'SVN::Notify'                => 0,
    },
    EXE_FILES           => ['bin/svn-wikify'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVN-Notify-Wiki-*' },
);
