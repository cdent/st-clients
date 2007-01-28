use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Socialtext::RemotelySimple',
    license             => 'perl',
    dist_author         => 'Socialtext, Inc <code@socialtext.com>',
    dist_version_from   => 'lib/Socialtext/RemotelySimple.pm',
    requires => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'URI::Escape'    => 0,
        'FindBin'        => 0,
        'File::Temp'     => 0,
        'YAML::Syck'     => 0,

    },
    add_to_cleanup      => [ 'Socialtext-RemotelySimple-*' ],
    script_files        => [ 'script/socialtexter', 'script/st-batch-delete' ],
);

$builder->create_build_script();
