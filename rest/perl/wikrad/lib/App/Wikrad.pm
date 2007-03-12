package App::Wikrad;
use strict;
use warnings;
use Curses::UI;
use Carp qw/croak/;
use base 'Exporter';
our @EXPORT_OK = qw/$App/;

our $VERSION = '0.01';

=head1 NAME

App::Wikrad - efficient wiki browsing and editing

=head1 SYNOPSIS

  my $app = App::Wikrad->new(rester => $rester);
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

    my $quitter = sub { $App->quit };
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
    my $wksp = $self->{win}{wksp};

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
    $self->{win}{wksp}->text($wksp);
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
    $self->{cui}->status("Loading page $current_page ...");
    my $page_text;
    if ($current_page) {
        $page_text = $self->{rester}->get_page($current_page);
    }
    else {
        $page_text = "^ Pages:\n\n";
        my @pages = $self->{rester}->get_pages;
        $page_text .= join "\n", 
                      map {"* [$_]"}
                      @pages;
    }
    $self->{win}{viewer}->text($page_text);
    $self->{win}{viewer}->cursor_to_home;
    $self->{cui}->nostatus;
}

sub _setup_ui {
    my $self = shift;
    $self->{cui} = Curses::UI->new( -color_support => 1 );
    $self->{win} = $self->{cui}->add('main', 'App::Wikrad::Window');
    $self->{cui}->leave_curses;
}

1;
