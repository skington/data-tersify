package Data::Tersify::Plugin::DBIx::Class;

use strict;
use warnings;

use DateTime;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Data::Tersify::Plugin::DBIx::Class - tersify DBIx::Class objects

=head1 SYNOPSIS

 use Data::Tersify;
 my $dbic_row = $schema->resultset(...)->find(...);
 print dumper(tersify($dbic_row));
 ### FIXME: what does this do?

=head1 DESCRIPTION

This class provides terse description for various types of DBIx::Class
objects.

=head2 handles

It handles DBIx::Class::ResultSource::Table objects only, for the moment.

=cut

sub handles { 'DBIx::Class::ResultSource::Table', 'DBIx::Class::ResultSet' }

=head2 tersify

It tersifies DBIx::Class::ResultSource::Table objects into just the name of
the table.

=cut

sub tersify {
    my ($self, $dbic_object) = @_;

    if (ref($dbic_object) eq 'DBIx::Class::ResultSource::Table') {
        return $dbic_object->{name};
    } elsif (ref($dbic_object) eq 'DBIx::Class::ResultSet') {
        return $dbic_object->{_result_class};
    }

    return 'FIXME';
}

1;

