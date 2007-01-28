package Socialtext::SoapSearcher;

# a quick hack to search multiple workspaces on multiple servers
# for the same query string.

use strict;
use warnings;
use Class::Field qw(field);
use Readonly;
use SOAP::Lite;

Readonly my $WSDL_PATH => '/static/wsdl/0.9.wsdl';

our %Soap;

field 'workspaces';
field 'destinations';
field 'username';
field 'password';

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = {@_};
    bless $self, $class;

    $self->_init();

    return $self;
}

sub query {
    my $self  = shift;
    my $query = shift;
    my @results;
    foreach my $destination ( @{ $self->destinations() } ) {
        my ( $server, $workspace ) = @$destination;
        my $soap = $self->_make_soap($server);

        # REVIEW: had been authing only at start but that led to some
        # difficulties debugging
        my $token
            = $soap->getAuth( $self->username, $self->password, $workspace );
        my $response = $soap->getSearch( $token, $query );
        foreach my $result (@$response) {
            push @results,
                $self->_make_result( $server, $workspace, $result );
        }
    }

    @results = sort { $b->{date} cmp $a->{date} } @results;

    return \@results;
}

sub _make_result {
    my $self = shift;
    my $server = shift;
    my $workspace = shift;
    my $result = shift;

    # XXX: this sure looks like an object
    return +{
        server => $server,
        workspace => $workspace,
        %$result,
    };
}

sub _init {
    my $self = shift;

    $self->_validate();
}

sub _make_soap {
    my $self   = shift;
    my $server = shift;


    my $soap = SOAP::Lite->service( $self->_make_wsdl($server) )->on_fault(
        sub {
            my ( $soap, $res ) = @_;
            die ref $res ? $res->faultstring : $soap->transport->status, "\n";
        }
    );

    return $soap;
}

sub _make_wsdl {
    my $self   = shift;
    my $server = shift;

    return 'https://' . $server . $WSDL_PATH;
}

sub _validate {
    my $self = shift;

    # XXX: Improve this
    die "username required"              unless $self->username;
    die "password required"              unless $self->password;
    die "destinations must be array ref" unless ref( $self->destinations );

}

1;
