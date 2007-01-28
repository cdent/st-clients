package Socialtext::WikiObject::Employee;
use strict;
use warnings;
use base 'Socialtext::WikiObject';
use Data::Dumper;

sub name {
    my $self = shift;
    return $self->{page};
}

sub phone_numbers {
    my $self = shift;
    my %info = $self->_parse_fields('phone', 
        qr/^(cell|mobile|fax|home|office|VOIP):\s*(.+)/i);
    return 'No phone info' unless %info;
    return join("\n", map { ucfirst($_) . ": $info{$_}" } sort keys %info);
}

sub chat_info {
    my $self = shift;
    my %info = $self->_parse_fields('chat', 
        qr/^(Yahoo IM|aim|skype|gizmo|jabber):\s*(.+)/i);
    return 'No chat info' unless %info;
    return join("\n", map { lc($_) . ":$info{$_}" } sort keys %info);
}

sub _parse_fields {
    my $self = shift;
    my $type = shift;
    my $field_regex = shift;

    my $contact_info = $self->{'contact information'} || 
                       $self->{'contact info'} ||
                       $self->{items};
    if (!$contact_info or !ref($contact_info)) {
        return;
    }

    $contact_info = $contact_info->{items} if ref($contact_info) eq 'HASH';

    my %info;
    for my $i (@$contact_info) {
        if ($i =~ $field_regex) {
            $info{$1} = $2;
        }
    }
    return %info;
}

1;
