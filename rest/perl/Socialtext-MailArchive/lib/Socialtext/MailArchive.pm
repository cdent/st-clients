package Socialtext::MailArchive;
use strict;
use warnings;
use Carp qw/croak/;

sub new {
    my $class = shift;
    my $self = {
        @_,
    };
    croak "rester is mandatory\n" unless $self->{rester};

    bless $self, $class;
    return $self;
}

sub archive_mail {
    my $self = shift;
    my $message = shift;
    my $r = $self->{rester};

    my ($msg_id, $subj) = $self->_parse_message($message);

    $r->put_page($msg_id, $message);
    $r->put_pagetag($msg_id, 'message');

    $self->update_thread($subj, $msg_id);
}

sub update_thread {
    my $self = shift;
    my $subj = shift;
    my $msg_id = shift;
    my $r = $self->{rester};

    my $thread = $r->get_page($subj);
    $thread = '' if $r->response->code eq '404';
    $thread .= "----\n" if $thread;
    $thread .= "{include [$msg_id]}\n";

    $r->put_page( $subj, $thread );
    $r->put_pagetag( $subj, 'thread' );
}

sub _parse_message {
    my $self = shift;
    my $msg = shift;

    my $subj = 'No subject - ' . localtime;
    if ($msg =~ /^Subject: (.+)$/m) {
        $subj = $1;
        $subj =~ s/^\[[^\]]+\]\s+//;
        $subj =~ s/^Re: //i;
    }

    my ($from, $date) = ('Unknown', scalar localtime);
    # Luke Closs - Test Mail - Mon, 5 Feb 2007 13:14:19
    if ($msg =~ /^From: (.+)$/m) {
        $from = $1;
        $from =~ s/\s+<.+//;
    }
    if ($msg =~ /^Date: (.+)$/m) {
        $date = $1;
    }
    return ("$from - $subj - $date", $subj);
}

1;
