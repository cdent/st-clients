package App::Wikrad::Window;
use strict;
use warnings;
use base 'Curses::UI::Window';
use Curses qw/KEY_ENTER/;
use App::Wikrad qw/$App/;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    #######################################
    # Create the Workspace label and field
    #######################################
    my $wksp_cb = sub { toggle_editable( shift, \&workspace_change ) };
    my $w = $self->{wksp} = $self->add_field('Workspace:', $wksp_cb,
        -text => $App->{rester}->workspace,
        -width => 18,
        -x => 1,
    );

    #######################################
    # Create the Page label and field
    #######################################
    my $page_cb = sub { toggle_editable( shift, sub { $App->load_page } ) };
    my $p = $self->{page_box} = $self->add_field('Page:', $page_cb,
        -width => 45,
        -x => 32,
    );

    #######################################
    # Create the Tag label and field
    #######################################
    my $tag_cb = sub { toggle_editable( shift, \&tag_change ) };
    my $t = $self->{tag} = $self->add_field('Tag:', $tag_cb,
        -width => 15,
        -x => 85,
    );

    #######################################
    # Create the page Viewer
    #######################################
    my $v = $self->{viewer} = $self->add(
        'viewer', 'App::Wikrad::PageViewer',
        -border => 1,
        -y      => 1,
    );

    $v->focus;
    $v->set_binding( \&editor, 'e');
    $v->set_binding( \&choose_frontlink, 'g');
    $v->set_binding( \&choose_backlink, 'B');
    $v->set_binding( \&show_help, '?');
    $v->set_binding( \&recently_changed, 'r');
    $v->set_binding( \&show_uri, 'u');
    $v->set_binding( sub { $v->focus }, 'v' );
    $v->set_binding( sub { $p->focus; $page_cb->($p) }, 'p' );
    $v->set_binding( sub { $w->focus; $wksp_cb->($w) }, 'w' );
    $v->set_binding( sub { $t->focus; $tag_cb->($t) }, 't' );
    $v->set_binding( sub { $App->go_back }, 'b' );

    return $self;
}

sub show_help {
    $App->{cui}->dialog(<<EOT);
Help:
 ? - show this help
 w - set workspace
 p - set page
 t - show tagged pages
 r - show recently changed pages
 u - show the uri for the current page

 ENTER - jump to page [under cursor]
 e - edit page
 g - choose a frontlink
 B - choose a backlink
 b - go back

 Ctrl-q / Ctrl-c / q - quit
EOT
}

sub listbox {
    my $self = shift;
    $App->{win}->add('listbox', 'App::Wikrad::Listbox', @_)->focus;
}

sub add_field {
    my $self = shift;
    my $desc = shift;
    my $cb = shift;
    my %args = @_;
    my $x = $args{-x} || 0;

    $self->add(undef, 'Label',
        -bold => 1,
        -text => $desc,
        -x => $x,
    );
    $args{-x} = $x + length($desc) + 1;
    my $w = $self->add(undef, 'TextEntry', 
        -singleline => 1,
        -sbborder => 1,
        -readonly => 1,
        %args,
    );
    $w->set_binding( sub { $cb->($w) }, KEY_ENTER );
    return $w;
}

sub show_uri {
    my $r = $App->{rester};
    my $uri = $r->server . '/' . $r->workspace 
              . '/index.cgi?' . $App->get_page;
    $App->{cui}->dialog( -title => "Current page:", -message => $uri );
}

sub recently_changed {
    my $r = $App->{rester};
    $App->{cui}->status('Fetching recent changes ...');
    my @recent = $r->get_taggedpages('Recent changes');
    $App->{cui}->nostatus;
    $App->{win}->listbox(
        -title => 'Choose a page link',
        -values => \@recent,
        change_cb => sub {
            my $link = shift;
            $App->set_page($link) if $link;
        },
    );
}

sub choose_frontlink {
    choose_link('get_frontlinks', 'Choose a page link');
}

sub choose_backlink {
    choose_link('get_backlinks', 'Choose a backlink');
}

sub choose_link {
    my $method = shift;
    my $text = shift;
    my $page = $App->get_page;
    my @links = $App->{rester}->$method($page);
    if (@links) {
        $App->{win}->listbox(
            -title => $text,
            -values => \@links,
            change_cb => sub {
                my $link = shift;
                $App->set_page($link) if $link;
            },
        );
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
        $App->set_page($r->get_homepage, $new_wksp);
    }
    else {
        my @workspaces = $r->get_workspaces;
        $App->{win}->listbox(
            -title => 'Choose a workspace',
            -values => \@workspaces,
            change_cb => sub {
                my $wksp = shift;
                $App->set_page($r->get_homepage, $wksp);
            },
        );
    }
}

sub tag_change {
    my $tag = $App->{win}{tag}->text;
    my $r = $App->{rester};
    if ($tag) {
        my @pages = $r->get_taggedpages($tag);
        $App->{win}->listbox(
            -title => 'Choose a tagged page',
            -values => \@pages,
            change_cb => sub {
                my $page = shift;
                $App->set_page($page) if $page;
            },
        );
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
        $w->cursor_to_home;
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
