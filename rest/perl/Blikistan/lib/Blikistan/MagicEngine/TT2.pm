package Blikistan::MagicEngine::TT2;
use strict;
use warnings;
use base 'Blikistan::MagicEngine';
use Template;
use FindBin;

sub render_template {
    my $self = shift;
    my $params = shift;
    my $r = $self->{rester};

    $params->{magic_engine} = ref($self);
    my $output = '';
    my $tmpl = $self->{template_name};
    if ($self->{template_page}) {
        $r->accept('text/x.socialtext-wiki');
        my $content = $r->get_page($self->{template_page});
        if ($r->response->code eq '404') {
            $content = $self->default_content;
        }
        $content =~ s/^\.pre\n(.+?)\.pre\n?.*/$1/s;
        $tmpl = \$content;
    }

    my $path = join ': ', 
               grep { defined }
               ($self->{template_path}, $FindBin::Bin);
    my $template = Template->new( { INCLUDE_PATH => $path } );
    $template->process( $tmpl, $params, \$output) or
        die $template->error;
    return $output;
}

sub default_content {
    my $self = shift;
    return <<EOT;
<html>
<head><title>Blikistan Problem</title></head>
<body>
Could not find template at $self->{template_page}

[% IF yaml_error %]
<strong>[% yaml_error %]</strong>
[% END %]
</body>
</html>
EOT
}

1;
