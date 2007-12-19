package Blikistan::MagicEngine::Dashboard;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use HTML::Truncate;
use Socialtext::Resting;

our $VERSION = '0.01';

sub print_blog {
    my $self = shift;
    $self->{rester}->workspace('dashboard-admin');
    $self->{template_page} = 'Dashboard Template';
    my $params = {
        last_tagged_page => sub { $self->last_tagged_page(@_) },
        names_and_tags   => sub { $self->names_and_tags(@_) },
        blog_posts       => sub { $self->blog_posts(@_) },
    };
    return $self->render_template($params);
}

sub last_tagged_page {
    my $self      = shift;
    my $workspace = shift;
    my $tag       = shift || return undef;
    my $chars     = shift;
    my $r         = $self->{rester};

    $r->workspace($workspace) if $workspace;
    $r->accept('text/plain');
    $r->order('newest');
    my @pages = $r->get_taggedpages($tag);

    my $page = shift @pages;
    $r->accept('text/html');
    my $p = $self->_load_page($page);

    if ($chars) {
        my $trunc = HTML::Truncate->new;
        $trunc->chars($chars);
        $p->{html} = $trunc->truncate($p->{html});
    }

    return {
        html => $p->{html},
        title => $p->{name},
        page_id => $p->{page_id},
    };
}

sub names_and_tags {
    my $self      = shift;
    my $workspace = shift;
    my $tag       = shift || return undef;
    my $count     = shift || 3;
    my $r         = $self->{rester};


    $r->workspace($workspace) if $workspace;
    $workspace = $r->workspace;

    $r->accept('text/plain');
    my @pages = $r->get_taggedpages($tag);
    my @names_and_tags;
    for my $p (@pages) {
        $r->accept('text/plain');
        my @tags = grep { $_ ne $tag } $r->get_pagetags($p);
        for my $t (@tags) {
            $t = qq(<a href="/$workspace/?action=category_display;)
                 . qq(category=$t">$t</a>);
        }

        push @names_and_tags, {
            name => $p,
            page_id => Socialtext::Resting::_name_to_id($p),
            tags => join(", ", @tags),
        };

        last if @names_and_tags == $count;
    }
    return \@names_and_tags;
}

sub blog_posts {
    my $self      = shift;
    my $workspace = shift;
    my $tag       = shift || return undef;
    my $posts     = shift || 3;
    my $chars     = shift || 200;
    my $r         = $self->{rester};

    my $trunc = HTML::Truncate->new;
    $trunc->chars($chars) if $chars;

    $r->workspace($workspace) if $workspace;
    $r->accept('text/plain');
    my @page_names = $r->get_taggedpages($tag);
    my @posts;
    for my $title (@page_names) {
        my $p = $self->_load_page($title);
        $p->{html} = $trunc->truncate($p->{html}) if $chars;
        
        (my $author = $p->{last_editor}) =~ s/\@.+//;
        push @posts, {
            title => $title,
            author => $author,
            date => scalar(localtime($p->{modified_time})),
            summary => $p->{html},
            page_id => Socialtext::Resting::_name_to_id($title),
        };

        last if @posts == $posts;
    }
    return \@posts;
}

1;
