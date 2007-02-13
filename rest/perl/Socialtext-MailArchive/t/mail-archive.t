#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Socialtext::MailArchive';
}


New_message: {
    my $r = Socialtext::Resting::Mock->new;
    $r->response->code(404);
    my $ma = Socialtext::MailArchive->new(rester => $r);
    isa_ok $ma, 'Socialtext::MailArchive';
    my $msg = fake_mail();
    $ma->archive_mail( $msg );
    my $mail_page = 'Luke Closs - Test Mail - Mon, 5 Feb 2007 13:14:19 -0800';
    is $r->get_page('Test Mail'), <<EOT;
{include [$mail_page]}
EOT
    is $r->get_page($mail_page), $msg;
}

Reply_message: {
    my $r = Socialtext::Resting::Mock->new;
    $r->response->code(404);
    my $ma = Socialtext::MailArchive->new(rester => $r);
    isa_ok $ma, 'Socialtext::MailArchive';
    my $msg = fake_mail();
    $ma->archive_mail( $msg );

    # hack message into a reply
    my $reply = $msg;
    $reply =~ s/^Subject: /Subject: re: /m;
    $reply =~ s/Mon, 5 Feb/Tue, 6 Feb/;
    $r->response->code(200);
    $ma->archive_mail( $reply );
    my $initial_mail = 'Luke Closs - Test Mail - Mon, 5 Feb 2007 13:14:19 -0800';
    my $second_mail = 'Luke Closs - Test Mail - Tue, 6 Feb 2007 13:14:19 -0800';
    is $r->get_page('Test Mail'), <<EOT;
{include [$initial_mail]}
----
{include [$second_mail]}
EOT
}

Bad_args: {
    eval { Socialtext::MailArchive->new };
    like $@, qr/rester is mandatory/;
}

Subject_with_special_characters: {
    ok 1;
}

Hide_signature: {
    ok 1;
}

sub fake_mail {
    return <<'EOT';
From lukec@ruby Mon Feb 05 13:14:39 2007
Received: from lukec by ruby with local (Exim 4.60)
	(envelope-from <lukec@ruby>)
	id 1HEBAT-0005RZ-Rr
	for append@ruby; Mon, 05 Feb 2007 13:14:29 -0800
Date: Mon, 5 Feb 2007 13:14:19 -0800
To: append@ruby
Subject: Test Mail
Message-ID: <20070205211419.GA20922@ruby>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.5.11
From: Luke Closs <lukec@ruby>

awe
EOT
}
