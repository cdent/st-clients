use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::Resting::Utils',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/Socialtext/Resting/Utils.pm',
    ABSTRACT_FROM       => 'lib/Socialtext/Resting/Utils.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting' => '0.15',
        'Test::More'          => 0,
        'Test::Mock::LWP'     => 0,
        'JSON'                => 0,
        'YAML'                => 0,
        },
    EXE_FILES           => ['bin/wikedit'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-Resting-Utils-*' },
);
