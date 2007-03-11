package App::Wikrad::PageViewer;
use strict;
use warnings;
use base 'Curses::UI::TextEditor';
use Curses qw/KEY_ENTER/;
use App::Wikrad qw/$App/;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        -vscrollbar => 1,
        -wrapping => 1,
        @_,
    );

    # disable all keys
    $self->set_binding( sub {}, '' );

    $self->set_binding( sub { $self->viewer_enter }, KEY_ENTER );
    $self->set_binding( sub { $self->cursor_down }, 'j' );
    $self->set_binding( sub { $self->cursor_up }, 'k' );
    $self->set_binding( sub { $self->cursor_right }, 'l' );
    $self->set_binding( sub { $self->cursor_left }, 'h' );

    return $self;
}

sub viewer_enter {
    my $self = shift;
    my $pos = $self->{-pos};
    my $text = $self->get;
    my $before_pos = substr($text, 0, $pos);
    #$cui->dialog("before: ($before_pos)");

    my @link_types = (
        [ '{link:? (\S+) \[' => '\]' ],
        [ '\[' => '\]' ],
    );
    my $link_text;
    my $new_wksp;
    for my $link (@link_types) {
        my ($pre, $post) = @$link;
        if ($before_pos =~ m/$pre([^$post]*)$/) {
            $link_text = $1;
            if ($2) {
                $link_text = $2;
                $new_wksp = $1;
            }
            my $after_pos = substr($text, $pos, -1);
            #$cui->dialog("after ($after_pos)");
            if ($after_pos =~ m/([^$post]*)$post/) {
                $link_text .= $1;
            }
            else {
                $link_text = undef;
                $new_wksp  = undef;
            }
        }
        last if $link_text;
    }

    $App->set_page($link_text, $new_wksp) if $link_text;
}

sub readonly($;)
{   
    my $this = shift;
    my $readonly = shift;

    $this->SUPER::readonly(1);
    $this->{-readonly} = $readonly;
    return $this;
}

1;
