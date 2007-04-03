package Socialtext::Wikrad;
use strict;
use warnings;
use Curses::UI;
use Carp qw/croak/;
use base 'Exporter';
our @EXPORT_OK = qw/$App/;

our $VERSION = '0.04';

=head1 NAME

Socialtext::Wikrad - efficient wiki browsing and editing

=head1 SYNOPSIS

  my $app = Socialtext::Wikrad->new(rester => $rester);
  $app->set_page( $starting_page );
  $app->run;

=cut

our $App;

sub new {
    my $class = shift;
    $App = { 
        history => [],
        @_ ,
    };
    die 'rester is mandatory' unless $App->{rester};
    bless $App, $class;
    $App->_setup_ui;
    return $App;
}

sub run {
    my $self = shift;

    my $quitter = sub { exit };
    $self->{cui}->set_binding( $quitter, "\cq");
    $self->{cui}->set_binding( $quitter, "\cc");
    $self->{win}{viewer}->set_binding( $quitter, 'q');

    $self->{cui}->reset_curses;
    $self->{cui}->mainloop;
}

sub set_page {
    my $self = shift;
    my $page = shift;
    my $workspace = shift;
    my $no_history = shift;

    my $pb = $self->{win}{page_box};
    my $wksp = $self->{win}{workspace_box};

    unless ($no_history) {
        push @{ $self->{history} }, {
            page => $pb->text,
            wksp => $wksp->text,
            pos  => $self->{win}{viewer}{-pos},
        };
    }
    $self->set_workspace($workspace) if $workspace;
    unless (defined $page) {
        $page = $self->{rester}->get_homepage;
    }
    $pb->text($page);
    $self->load_page;
}

sub set_workspace {
    my $self = shift;
    my $wksp = shift;
    $self->{win}{workspace_box}->text($wksp);
    $self->{rester}->workspace($wksp);
}

sub go_back {
    my $self = shift;
    my $prev = pop @{ $self->{history} };
    if ($prev) {
        $self->set_page($prev->{page}, $prev->{wksp}, 1);
        $self->{win}{viewer}{-pos} = $prev->{pos};
    }
}

sub get_page {
    return $App->{win}{page_box}->text;
}

sub load_page {
    my $self = shift;
    my $current_page = $self->{win}{page_box}->text;

    if (! $current_page) {
        $self->{cui}->status('Fetching list of pages ...');
        my @pages = $self->{rester}->get_pages;
        $self->{cui}->nostatus;
        $App->{win}->listbox(
            -title => 'Choose a page',
            -values => \@pages,
            change_cb => sub {
                my $page = shift;
                $App->set_page($page) if $page;
            },
        );
        return;
    }

    $self->{cui}->status("Loading page $current_page ...");
    my $page_text = $self->{rester}->get_page($current_page);
    $self->{cui}->nostatus;
    $self->{win}{viewer}->text($page_text);
    $self->{win}{viewer}->cursor_to_home;
}

sub _setup_ui {
    my $self = shift;
    $self->{cui} = Curses::UI->new( -color_support => 1 );
    $self->{win} = $self->{cui}->add('main', 'Socialtext::Wikrad::Window');
    $self->{cui}->leave_curses;
}

1;
