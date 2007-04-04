use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::Blikistan::DevBlogs',
    AUTHOR              => 'Luke Closs <luke@socialtext.com>',
    VERSION_FROM        => 'lib/Socialtext/Blikistan/DevBlogs.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting::Utils' => '0.04',
        'Blikistan'                  => '0.04',
    },
    EXE_FILES           => [],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-*' },
);
