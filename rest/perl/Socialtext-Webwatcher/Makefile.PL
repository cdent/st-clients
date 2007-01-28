use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Socialtext-Webwatcher',
    'VERSION'      => '0.01',
    'PREREQ_PRINT' => 1,
    'EXE_FILES'    => ['st-webwatcher'],
    'PREREQ_PM'    => {
        JSON                  => 1.07,
        'Socialtext::Resting' => 0.10,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT => 'Remind owners of stale wiki pages.',
            AUTHOR   => "Chris Dent <chris.dent\@socialtext.com>, "
                . "Matthew O'Connor <matthew.oconnor\@socialtext.com>"
            )
        : ()
    ),
);
