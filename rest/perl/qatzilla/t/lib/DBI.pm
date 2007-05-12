package DBI;
1;

sub connect {
    return bless {}, shift;
}

sub prepare {
    return shift;
}

sub fetchrow_array {
}

sub execute {
}

sub finish {
}
