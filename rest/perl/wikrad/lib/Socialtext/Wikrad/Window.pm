package Socialtext::Wikrad::Window;
use strict;
use warnings;
use base 'Curses::UI::Window';
use Curses qw/KEY_ENTER/;
use Socialtext::Wikrad qw/$App/;
use Socialtext::Resting;
use JSON;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->_create_ui_widgets;

    my ($v, $p, $w, $t) = map { $self->{$_} } 
                          qw/viewer page_box workspace_box tag_box/;
    $v->focus;
    $v->set_binding( \&choose_frontlink, 'g' );
    $v->set_binding( \&choose_backlink,  'B' );
    $v->set_binding( \&show_help,        '?' );
    $v->set_binding( \&recently_changed, 'r' );
    $v->set_binding( \&show_uri,         'u' );
    $v->set_binding( \&show_includes,    'i' );
    $v->set_binding( \&clone_page,       'c' );
    $v->set_binding( \&show_metadata,    'm' );
    $v->set_binding( \&add_pagetag,      'T' );

    $v->set_binding( sub { editor() },                  'e' );
    $v->set_binding( sub { editor('--pull-includes') }, 'E' );
    $v->set_binding( sub { $v->focus },                 'v' );
    $v->set_binding( sub { $p->focus; $self->{cb}{page}->($p) },      'p' );
    $v->set_binding( sub { $w->focus; $self->{cb}{workspace}->($w) }, 'w' );
    $v->set_binding( sub { $t->focus; $self->{cb}{tag}->($t) },       't' );

    $v->set_binding( sub { $v->viewer_enter }, KEY_ENTER );
    $v->set_binding( sub { $App->go_back }, 'b' );

    # this n/N messes up search next/prev
    $v->set_binding( sub { $v->next_link },    'n' );
    $v->set_binding( sub { $v->prev_link },    'N' );

    $v->set_binding( sub { $v->cursor_down },  'j' );
    $v->set_binding( sub { $v->cursor_up },    'k' );
    $v->set_binding( sub { $v->cursor_right }, 'l' );
    $v->set_binding( sub { $v->cursor_left },  'h' );
    $v->set_binding( sub { $v->cursor_to_home }, '0' );
    $v->set_binding( sub { $v->cursor_to_end },  'G' );

    return $self;
}

sub show_help {
    $App->{cui}->dialog( 
        -fg => 'yellow',
        -bg => 'blue',
        -title => 'Help:',
        -message => <<EOT);
Navigation:
 w - set workspace
 p - set page
 t - choose from tagged pages
 r - choose from recently changed pages
 g - choose from the frontlinks
 B - choose from the backlinks
 e - open page for edit
 E - open page for edit (--pull-includes)
 b - go back
 u - show the uri for the current page
 i - show included pages
 c - clone this page
 m - show page metadata (tags, revision)
 T - Tag page

Movement:
 ENTER   - jump to page [under cursor]
 n/N     - move to next/previous link
 h/l/j/k - left/right/down/up
 0/G     - move to beginning/end of page
 space/- - page down/up

Search:
 / - search forward
 ? - search backwards 
 (search n/N conflicts with next/prev link)

Ctrl-q / Ctrl-c / q - quit
EOT
}

sub add_pagetag {
    my $r = $App->{rester};
    $App->{cui}->status('Fetching page tags ...');
    $r->accept('text/plain');
    my $page_name = $App->get_page;
    my @tags = $r->get_pagetags($page_name);
    $App->{cui}->nostatus;
    my $question = "Enter new tags, separate with commas, prefix with '-' to remove\n  ";
    if (@tags) {
        $question .= join(", ", @tags) . "\n";
    }
    my $newtags = $App->{cui}->question($question) || '';
    my @new_tags = split(/\s*,\s*/, $newtags);
    if (@new_tags) {
        $App->{cui}->status("Tagging $page_name ...");
        for my $t (@new_tags) {
            if ($t =~ s/^-//) {
                eval { $r->delete_pagetag($page_name, $t) };
            }
            else {
                $r->put_pagetag($page_name, $t);
            }
        }
        $App->{cui}->nostatus;
    }
}

sub show_metadata {
    my $r = $App->{rester};
    $App->{cui}->status('Fetching page metadata ...');
    $r->accept('application/json');
    my $page_name = $App->get_page;
    my $json_text = $r->get_page($page_name);
    my $page_data = jsonToObj($json_text);
    $App->{cui}->nostatus;
    $App->{cui}->dialog(
        -title => "$page_name metadata",
        -message => Dumper $page_data,
    );
}

sub show_uri {
    my $r = $App->{rester};
    my $uri = $r->server . '/' . $r->workspace 
              . '/index.cgi?' 
              . Socialtext::Resting::_name_to_id($App->get_page);
    $App->{cui}->dialog( -title => "Current page:", -message => " $uri" );
}

sub clone_page {
    my $r = $App->{rester};
    my $template_page = $App->get_page;
    $r->accept('text/x.socialtext-wiki');
    my $template = $r->get_page($template_page);
    my $new_page = $App->{cui}->question("Title for new page:");
    $App->{cui}->status("Creating page ...");
    $r->put_page($new_page, $template);
    $r->accept('text/plain');
    my @tags = $r->get_pagetags($template_page);
    $r->put_pagetag($new_page, $_) for @tags;
    $App->{cui}->nostatus;

    $App->set_page($new_page);
}

sub show_includes {
    my $r = $App->{rester};
    my $viewer = $App->{win}{viewer};
    $App->{cui}->status('Fetching included pages ...');
    my $page_text = $viewer->text;
    while($page_text =~ m/\{include:? \[(.+?)\]\}/g) {
        my $included_page = $1;
        $r->accept('text/x.socialtext-wiki');
        my $included_text = $r->get_page($included_page);
        my $new_text = "-----Included Page----- [$included_page]\n"
                       . "$included_text\n"
                       . "-----End Include----- \n";
        $page_text =~ s/{include:? \[\Q$included_page\E\]}/$new_text/;
    }
    $viewer->text($page_text);
    $App->{cui}->nostatus;
}

sub recently_changed {
    my $r = $App->{rester};
    $App->{cui}->status('Fetching recent changes ...');
    $r->accept('text/plain');
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
    choose_link('get_frontlinks', 'page link');
}

sub choose_backlink {
    choose_link('get_backlinks', 'backlink');
}

sub choose_link {
    my $method = shift;
    my $text = shift;
    my $arg = shift;
    my $page = $App->get_page;
    $App->{cui}->status("Fetching ${text}s");
    $App->{rester}->accept('text/plain');
    my @links = $App->{rester}->$method($page, $arg);
    $App->{cui}->nostatus;
    if (@links) {
        $App->{win}->listbox(
            -title => "Choose a $text",
            -values => \@links,
            change_cb => sub {
                my $link = shift;
                $App->set_page($link) if $link;
            },
        );
    }
    else {
        $App->{cui}->error("No ${text}s");
    }
}

sub editor {
    my @extra_args = @_;
    $App->{cui}->status('Editing page');
    $App->{cui}->leave_curses;
    my $r = $App->{rester};
    my $workspace = $r->workspace;
    my $page = $App->get_page;
    my $server = $r->server;
    system("wikedit", '-s', $server, '-w', $workspace, @extra_args, $page);
    $App->{cui}->reset_curses;
    $App->load_page;
}

sub workspace_change {
    my $new_wksp = $App->{win}{workspace_box}->text;
    my $r = $App->{rester};
    if ($new_wksp) {
        $App->set_page(undef, $new_wksp);
    }
    else {
        $App->{cui}->status('Fetching list of workspaces ...');
        $r->accept('text/plain');
        my @workspaces = $r->get_workspaces;
        $App->{cui}->nostatus;
        $App->{win}->listbox(
            -title => 'Choose a workspace',
            -values => \@workspaces,
            change_cb => sub {
                my $wksp = shift;
                $App->set_page(undef, $wksp);
            },
        );
    }
}

sub tag_change {
    my $r = $App->{rester};
    my $tag = $App->{win}{tag_box}->text;

    my $chose_tagged_page = sub {
        my $tag = shift;
        $App->{cui}->status('Fetching tagged pages ...');
        $r->accept('text/plain');
        my @pages = $r->get_taggedpages($tag);
        $App->{cui}->nostatus;
        if (@pages == 0) {
            $App->{cui}->dialog("No pages tagged '$tag' found ...");
            return;
        }
        $App->{win}->listbox(
            -title => 'Choose a tagged page',
            -values => \@pages,
            change_cb => sub {
                my $page = shift;
                $App->set_page($page) if $page;
            },
        );
    };
    if ($tag) {
        $chose_tagged_page->($tag);
    }
    else {
        $App->{cui}->status('Fetching workspace tags ...');
        $r->accept('text/plain');
        my @tags = $r->get_workspace_tags;
        $App->{cui}->nostatus;
        $App->{win}->listbox(
            -title => 'Choose a tag:',
            -values => \@tags,
            change_cb => sub {
                my $tag = shift;
                $chose_tagged_page->($tag) if $tag;
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

sub _create_ui_widgets {
    my $self = shift;
    #######################################
    # Create the Workspace label and field
    #######################################
    my $wksp_cb = sub { toggle_editable( shift, \&workspace_change ) };
    $self->{cb}{workspace} = $wksp_cb;
    $self->{workspace_box} = $self->add_field('Workspace:', $wksp_cb,
        -text => $App->{rester}->workspace,
        -width => 18,
        -x => 1,
    );

    #######################################
    # Create the Page label and field
    #######################################
    my $page_cb = sub { toggle_editable( shift, sub { $App->load_page } ) };
    $self->{cb}{page} = $page_cb;
    $self->{page_box} = $self->add_field('Page:', $page_cb,
        -width => 45,
        -x => 32,
    );

    #######################################
    # Create the Tag label and field
    #######################################
    my $tag_cb = sub { toggle_editable( shift, \&tag_change ) };
    $self->{cb}{tag} = $tag_cb;
    $self->{tag_box} = $self->add_field('Tag:', $tag_cb,
        -width => 15,
        -x => 85,
    );

    $self->add(undef, 'Label',
        -x => 107,
        -bold => 1,
        -text => "Help: hit '?'"
    );

    #######################################
    # Create the page Viewer
    #######################################
    $self->{viewer} = $self->add(
        'viewer', 'Socialtext::Wikrad::PageViewer',
        -border => 1,
        -y      => 1,
    );
}

sub listbox {
    my $self = shift;
    $App->{win}->add('listbox', 'Socialtext::Wikrad::Listbox', @_)->focus;
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

1;
