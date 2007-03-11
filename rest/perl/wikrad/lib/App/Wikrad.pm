package App::Wikrad;
use strict;
use warnings;
use Curses::UI;
use Term::ANSIColor ':constants';
use Carp qw/croak/;
use base 'Exporter';
our @EXPORT_OK = qw/$App/;

our $App;

sub new {
    my $class = shift;
    $App = { @_ };
    die 'rester is mandatory' unless $App->{rester};
    bless $App, $class;
    $App->_setup_ui;
    return $App;
}

sub run {
    my $self = shift;
    $self->{cui}->set_binding( \&quitter, "\cq");
    $self->{cui}->reset_curses;
    $self->{cui}->mainloop;
}

sub set_page {
    my $self = shift;
    my $page = shift;

    croak "no window!" unless $self->{win};
    my $pb = $self->{win}{page_box};
    croak "no pagebox!" unless $pb;
    $pb->text($page);
    $self->load_page;
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
    $page_text = colorize_text($page_text);
    $self->{win}{viewer}->text($page_text);
    $self->{cui}->nostatus;
}

sub _setup_ui {
    my $self = shift;
    $self->{cui} = Curses::UI->new( -color_support => 1 );
    $self->{win} = $self->{cui}->add('main', 'App::Wikrad::Window');
    $self->{cui}->leave_curses;
}

sub colorize_text {
    my $text = shift;

    return $text;
}

1;
