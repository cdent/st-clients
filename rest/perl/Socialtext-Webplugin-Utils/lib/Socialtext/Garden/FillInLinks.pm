package Socialtext::Garden::FillInLinks;
use strict;
use warnings;
use Socialtext::Resting;

sub new {
    my $class = shift;
    my %opts  = @_;

    my $self = { @_ };
    for (qw/cgi rester/) {
        die "$_ is mandatory!\n" unless $self->{$_};
    }

    for (qw/page workspace matching template/) {
        $self->{$_} = $self->{cgi}->param($_);
        die "$_ is mandatory!\n" unless $self->{$_};
    }

    bless $self, $class;
    return $self;
}

sub run {
    my $self = shift;
    my $r = $self->{rester};
    $r->workspace($self->{workspace});

    $r->accept('text/plain');
    my %links = map { $_ => 1 } $r->get_frontlinks($self->{page}, 'incipient links please');

    my $response = '';
    my @to_clone;

    # Look for links in the page manually, so we can pull out the real
    # title of the link (not the page_id)
    $r->accept('text/x.socialtext-wiki');
    my $page_text = $r->get_page($self->{page});
    while ($page_text =~ m/\[([^\]]+)\]/g) {
        my $link_text = $1;
        next unless $links{Socialtext::Resting::name_to_id($link_text)};
        unless ($link_text =~ m/\Q$self->{matching}\E/i) {
            $response .= "Link ($link_text) doesn't match $self->{matching}<br />";
            next;
        }

        push @to_clone, $link_text;
    }

    unless (@to_clone) {
        $response .= "No links to clone!<br/>";
        return $response;
    }

    $r->accept('text/x.socialtext-wiki');
    my $template = $r->get_page($self->{template});
    for my $page (@to_clone) {
        $response .= "Cloned $self->{template} to $page.<br />";
        $r->put_page($page, $template);
    }

    return $response;
}

1;
