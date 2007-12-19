package Blikistan::MagicEngine::Simple;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use URI::Escape;

sub print_blog {
    my $self = shift;
    return $self->render_template( $self->load_config );
}

1;

