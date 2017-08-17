#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Scalar::Util qw(refaddr);
use Test::More;

use Data::Tersify qw(tersify);
use TestObject;

test_basic_structures_unchanged();
test_plugin();

done_testing();

sub test_basic_structures_unchanged {
    # Basic structures.
    is_deeply(tersify('foo'), 'foo', 'Simple scalars pass through');
    my @array = qw(foo bar baz);
    is_deeply(tersify(\@array), \@array,
        'Simple arrays pass through unchanged');
    my %hash = (foo => 'toto', bar => 'titi', baz => 'tata');
    is_deeply(tersify(\%hash), \%hash,
        'Simple hashes pass through unchanged');

    # It's the same structures we get back.
    is(tersify(\@array), \@array, q{It's the same simple array});
    is(tersify(\%hash), \%hash, q{It's the same simple hash also});

    # Complex structures also go through unchanged.
    my %complex_structure = (
        sins    => [qw(pride greed lust envy gluttony wrath sloth)],
        virtues => [
            qw(prudence justice temperance courage
                faith hope charity)
        ],
        balance => {
            economy => {
                charity => [
                    'RSPB', 'Oxfam', ['Cat home', 'Dog home'],
                    {
                        'Cancer Research'          => '10 GBP per month',
                        'British Heart Foundation' => {
                            donate    => '5 GBP per month',
                            volunteer => ['Mondays', 'Thursdays'],
                        }
                    }
                ],
                greed => 'Those cakes are nice. Or is that gluttony?',
            }
        }
    );
    is_deeply(tersify(\%complex_structure),
        \%complex_structure,
        'A structure with many nested arrayrefs and hashrefs is untouched');
}

sub test_plugin {
    my $object = TestObject->new;
    $object->id(42);

    # Basic tests
    is(tersify($object), $object,
        'An object passed directly is not tersified');
    my $tersified = tersify({object => $object });
    is_deeply([keys %$tersified],
        ['object'], 'Still have just the one key called object');
    is(ref($tersified->{object}),
        'Data::Tersify::Summary',
        'The object value is now our summary object');
    like(
        ${ $tersified->{object} },
        qr/^ TestObject \s \( 0x [0-9a-f]+ \) \s ID \s 42 $/x,
        'The object got summarised as a scalar reference'
    );
}
