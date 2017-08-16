package Data::Tersify;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(tersify);

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Data::Tersify - generate terse equivalents of complex data structures

=head1 SYNOPSIS

 use Data::Dumper;
 use Data::Tersify;
 
 my $complicated_data_structure = ...;
 
 print Dumper(tersify($complicated_data_structure));
 # Your scrollback is not full of DateTime, DBIx::Class, Moose etc.
 # spoor which you weren't interested in.

=head1 DESCRIPTION

Complex data structures are useful; necessary, even. But they're not
I<helpful>. In particular, when you're buried in the guts of some code
you don't fully understand and you have a variable you want to inspect,
and you say C<x $foo> in the debugger, or C<print STDERR Dumper($foo)> from
your code, or something very similar with the dumper module of your choice,
and you then get I<pages upon pages of unhelpful stuff> because C<$foo>
contained a reference to a DateTime, DBIx::Class, Moose or other verbose
object... you didn't need that.

Data::Tersify looks at any data structure it's given, and if it finds a
blessed object that it knows about, it replaces it in the data structure
by a terser equivalent, designed to (a) not use up all of your scrollback,
but (b) be blatantly clear that this is I<not> the original object that
was in that data structure originally, but a terser equivalent.

Do not use Data::Tersify as part of any serialisation implementation! By
design, Data::Tersify is lossy and will throw away information! It supposes,
though, that if you're using it, you want to dump information about a complex
data structure, and you don't I<care> about the fine details.

=cut

1;