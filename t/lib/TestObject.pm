package TestObject;

use strict;
use warnings;

sub new {
    return bless {} => shift || __PACKAGE__;
}

sub id {
    my $self = shift;
    if (@_) {
        $self->{id} = shift;
    }
    $self->{id};
}

1;
