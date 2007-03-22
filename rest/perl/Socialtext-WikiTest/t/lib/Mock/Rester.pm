package Mock::Rester;
use strict;
use warnings;

sub new {
    my ($class, %opts) = @_;
    my $self = \%opts;
    bless $self, $class;
    return $self;
}

sub put_page {
    my ($self, $page, $content) = @_;
    $self->{page}{$page} = $content;
}

sub get_page {
    my ($self, $page) = @_;
    return delete $self->{page}{$page};
}

sub put_pagetag {
    my ($self, $page, $tag) = @_;
    push @{$self->{page_tags}{$page}}, $tag;
}

sub get_pagetags {
    my ($self, $page) = @_;
    return delete $self->{page_tags}{$page};
}

1;
