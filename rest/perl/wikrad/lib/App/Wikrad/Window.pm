package App::Wikrad::Window;
use strict;
use warnings;
use base 'Curses::UI::Window';
use Curses qw/KEY_ENTER/;
use App::Wikrad qw/$App/;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->add(undef, 'Label',
        -bold => 1,
        -text => 'Workspace:',
    );

    my $w = $self->{wksp} = $self->add('workspace', 'TextEntry', 
        -text => $App->{rester}->workspace,
        -singleline => 1,
        -width => 15,
        -x => 12,
        -readonly => 1,
    );
    my $wksp_cb = sub { toggle_editable( $w, \&workspace_change ) };
    $w->set_binding( $wksp_cb, KEY_ENTER );

    $self->add( undef, 'Label',
        -bold => 1, 
        -text => 'Page:', 
        -x => 34,
    );
    my $p = $self->{page_box} = $self->add('page', 'TextEntry', 
        -singleline => 1,
        -width => 45,
        -x => 40,
        -readonly => 1,
    );
    my $page_cb = sub { toggle_editable( $p, sub { $App->load_page } ) };
    $p->set_binding( $page_cb, KEY_ENTER );

    $self->add(undef, 'Label',
        -bold => 1,
        -text => 'Tag:',
        -x => 90,
    );
    my $t = $self->{tag} = $self->add('tag', 'TextEntry', 
        -singleline => 1,
        -width => 15,
        -x => 95,
        -readonly => 1,
    );
    my $tag_cb = sub { toggle_editable( $t, \&tag_change ) };
    $t->set_binding( $tag_cb, KEY_ENTER );

    my $v = $self->{viewer} = $self->add(
        'viewer', 'App::Wikrad::PageViewer',
        -border => 1,
        -y      => 1,
    );

    $v->focus;
    $v->set_binding( \&quitter, 'q');
    $v->set_binding( \&editor, 'e');
    $v->set_binding( \&choose_link, 'l');
    $v->set_binding( sub { $v->focus }, 'v' );
    $v->set_binding( sub { $p->focus; $page_cb->() }, 'p' );
    $v->set_binding( sub { $w->focus; $wksp_cb->() }, 'w' );
    $v->set_binding( sub { $t->focus; $tag_cb->() }, 't' );

    return $self;
}

sub choose_link {
    my $text = $App->{win}{viewer}->text;
    my %links;
    while ($text =~ m/\[([^\]]+)\]/g) {
        my $link = $1;
        next if grep { m/^\Q$link\E$/i } keys %links;
        $links{$1}++;
    }

    my @links = keys %links;
    if (@links) {
        my $popup = $App->{win}->add('link_popup', 'Listbox',
            -title => 'Choose a page link',
            -values => \@links,
            -modal => 1,
            -onchange => sub {
                my $w = shift;
                my $link = $w->get;
                $App->{win}->delete('link_popup');
                $App->{win}->draw;
                $App->set_page($link) if $link;
            },
        );
        $popup->focus;
    }
}

sub editor {
    $App->{cui}->status('Editing page');
    $App->{cui}->leave_curses;
    my $r = $App->{rester};
    my $workspace = $r->workspace;
    my $page = $App->get_page;
    my $server = $r->server;
    system("wikedit -s '$server' -w '$workspace' '$page'");
    $App->{cui}->reset_curses;
    $App->load_page;
}

sub workspace_change {
    my $new_wksp = $App->{win}{wksp}->text;
    my $r = $App->{rester};
    if ($new_wksp) {
        $r->workspace($new_wksp);
        $App->set_page($r->get_homepage);
    }
    else {
        my @workspaces = $r->get_workspaces;
        my $popup = $App->{win}->add('wksp_popup', 'Listbox',
            -title => 'Choose a workspace',
            -values => \@workspaces,
            -modal => 1,
            -onchange => sub {
                my $w = shift;
                my $wksp = $w->get;
                $r->workspace($wksp);

                $App->{win}->delete('wksp_popup');
                $App->{win}->draw;
                $App->set_page($r->get_homepage);
            },
        );
        $popup->focus;
    }
}

sub tag_change {
    my $tag = $App->{win}{tag}->text;
    my $r = $App->{rester};
    if ($tag) {
        my @pages = $r->get_taggedpages($tag);
        my $popup = $App->{win}->add('tag_popup', 'Listbox',
            -title => 'Choose a tagged page',
            -values => \@pages,
            -modal => 1,
            -onchange => sub {
                my $w = shift;
                my $page = $w->get;

                $App->{win}->delete('tag_popup');
                $App->{win}->draw;
                $App->set_page($page) if $page;
            },
        );
        $popup->focus;
    }
}

sub toggle_editable {
    my $w = shift;
    my $cb = shift;
    my $readonly = $w->{'-readonly'};

    my $new_text = $w->text;
    $new_text =~ s/^\s*(.+?)\s*$/$1/;
    $w->text($new_text);

    if ($readonly) {
        $w->cursor_to_end;
        $w->focus;
    }
    else {
        $App->{win}{viewer}->focus;
    }

    $cb->() if $cb and !$readonly;
    $w->readonly(!$readonly);
    $w->set_binding( sub { toggle_editable($w, $cb) }, KEY_ENTER );
}

1;
