use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %config = (
    'NAME'         => 'picblog',
    'VERSION' => '0.1',
    'PREREQ_PRINT' => 1,
    'EXE_FILES'    => [
        'bin/picblog',
    ],
    'PREREQ_PM' => {
        'Socialtext::Resting' => 0,
        'Flickr::API' => 0,
        'XML::Parser::Lite::Tree::XPath' => 0,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT => 'Simple tool to to make a daily blog',
            AUTHOR   =>
                'Chris Dent <chris.dent@socialtext.com>'
            )
        : ()
    ),
);

WriteMakefile(%config);
