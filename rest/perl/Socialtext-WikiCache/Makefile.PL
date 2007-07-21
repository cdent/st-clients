use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::WikiCache',
    AUTHOR              => 'Luke Closs <luke@socialtext.com>',
    VERSION_FROM        => 'lib/Socialtext/WikiCache.pm',
    ABSTRACT_FROM       => 'lib/Socialtext/WikiCache.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting' => '0.20',
        'Test::More'          => 0,
        'JSON'                => 0,
        },
    EXE_FILES           => [
        'bin/st-sync-workspace',
    ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-WikiCache-*' },
);
