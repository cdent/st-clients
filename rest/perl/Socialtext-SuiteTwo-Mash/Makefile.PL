use ExtUtils::MakeMaker;

WriteMakefile(
               NAME          => 'Socialtext::SuiteTwo::Mash',
               VERSION_FROM  => 'lib/Socialtext/SuiteTwo/Mash.pm',
               PREREQ_PM     => {
                                 'Test::More' => '',
                                 'LWP::UserAgent' => '',
                                 'HTTP::Request' => '',
                                 'URI::Escape' => '',
                                 'JSON::Syck' => '',
                                 'Text::Context' => '',
                                 'Class::Accessor' => '',
                                },
);