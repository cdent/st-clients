package Socialtext::PeopleDirectory;
use strict;
use warnings;
use Socialtext::WikiObject::Employee;
use Template;

sub new {
    my ($class, %opts) = @_;
    my $self = {
        tag => 'employee',
        destination_page => 'People Directory',
        commit => 1,
        template => undef,
        %opts,
    };
    die 'rester is mandatory!' unless $self->{rester};
    bless $self, $class;
}

sub generate_directory {
    my $self = shift;
    my $rester = $self->{rester};


    my @pages = $rester->get_taggedpages($self->{tag});
    my @people;
    for my $name (sort @pages) {
        print "$name...\n";
        my $emp = Socialtext::WikiObject::Employee->new(rester => $rester, 
                                                        page => $name);
        push @people, { 
            name  => $name,
            phone => $emp->phone_numbers,
            chat  => $emp->chat_info,
        };
    }

    my $tt2 = Template->new;
    my $template = $self->{template} || <<EOT;
| Name | Phone | Chat |
[% FOR p IN people -%]
| [[% p.name %]] | [% p.phone %] | [% p.chat %] |
[% END %]
Auto-generated at [% date %] from all people tagged with 'hacker'.
EOT
    my $new_info;
    my $opts = {
        people => \@people,
        date => scalar(localtime),
        tag => $self->{tag},
    };
    $tt2->process(\$template, $opts, \$new_info) or die $tt2->error(), "\n";
    $rester->put_page('People Directory', $new_info) if $self->{commit};
    return $new_info;
}

1;
