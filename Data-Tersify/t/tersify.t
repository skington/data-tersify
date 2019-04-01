#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Scalar::Util qw(refaddr);
use Test::More;

use Data::Tersify qw(tersify);
use TestObject;
use TestObject::Overloaded;
use TestObject::Overloaded::JustImport;
use TestObject::Overloaded::OtherOperator;
use TestObject::WithName;
use TestObject::WithUUID;

my $re_refaddr = qr{ \( 0x [0-9a-f]+ \) }x;

subtest 'Basic structures are unchanged' => \&test_basic_structures_unchanged;
subtest 'Plugins'                        => \&test_plugin;
subtest 'We can tersify other objects'   => \&test_tersify_other_objects;
subtest 'We avoid infinite loops'        => \&test_avoid_infinite_loops;
subtest 'Overloaded stringification'     => \&test_stringification;

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
    my $object = TestObject->new(42);

    # Basic tests
    is(tersify($object), $object,
        'An object passed directly is not tersified');
    my $tersified = tersify({object => $object });
    is_deeply([keys %$tersified], ['object'],
        'Still have just the one key called object');
    is(ref($tersified->{object}),
        'Data::Tersify::Summary',
        'The object value is now our summary object');
    like(
        ${ $tersified->{object} },
        qr/^ TestObject \s $re_refaddr \s ID \s 42 $/x,
        'The object got summarised as a scalar reference'
    );

    # Structures containing tersified objects are returned modified,
    # as are any parent structures. Other structures are unaffected.
    my $emergency_object = TestObject->new(999);
    my $deep_object      = TestObject->new(5683);
    my $original = {
        meh => [
            'mumbo', 'jumbo',
            {
                faff => 'nonsense',
            }
        ],
        emergency      => $emergency_object,
        deep_structure => {
            many => {
                layers => {
                    until => $deep_object,
                }
            }
        }
    };
    $tersified = tersify($original);
    is_deeply(
        $tersified->{meh},
        ['mumbo', 'jumbo', { faff => 'nonsense' }],
        'The data structure with no objects is unaffected'
    );
    is(
        refaddr($tersified->{meh}),
        refaddr($original->{meh}),
        q{In fact it's the same structure}
    );
    isnt(refaddr($tersified), refaddr($original),
        'But the root structure is different');
    like(
        ${$tersified->{emergency}},
        qr{^ TestObject \s $re_refaddr \s ID \s 999 $}x,
        'The emergency test object was summarised'
    );
    like(${$tersified->{deep_structure}{many}{layers}{until}},
        qr{^ TestObject \s $re_refaddr \s ID \s 5683 $}x,
        'The deep test object was summarised');
    isnt(
        refaddr($tersified->{deep_structure}),
        refaddr($original->{deep_structure}),
        'The deep structure is also a new hash'
    );
    isnt(
        refaddr($tersified->{deep_structure}{many}),
        refaddr($original->{deep_structure}{many}),
        'As is many'
    );
    isnt(
        refaddr($tersified->{deep_structure}{many}{layers}),
        refaddr($original->{deep_structure}{many}{layers}),
        'And layers'
    );
    is(ref($original->{emergency}), 'TestObject',
        'We still have the original emergency object');
    is(ref($original->{deep_structure}{many}{layers}{until}), 'TestObject',
        'We also have the deep object');

    # Plugins can say that they handle multiple types of object.
    my $original_multiple = {
        id => 12,
        name => TestObject::WithName->new('Bob'),
        uuid => TestObject::WithUUID->new('1234567890AB-or-something'),
        'is that even a real UUID?' => 'no, who cares?',
    };
    my $tersified_multiple = tersify($original_multiple);
    like(
        ${ $tersified_multiple->{name} },
        qr{^ TestObject::WithName \s $re_refaddr \s Name \s Bob $}x,
        'The named object was summarised'
    );
    like(
        ${ $tersified_multiple->{uuid} },
        qr{^ TestObject::WithUUID \s $re_refaddr \s UUID \s 123456.+ $}x,
        'The object with a UUID was summarised'
    );
    
}

sub test_tersify_other_objects {
    # Objects without anything inside them aren't tersified.
    my $simple_object = bless { number => 1, other_number => 'also 1' },
        'Simple';
    my $structure = { simple_object => $simple_object };
    my $tersified = tersify($structure);
    is_deeply($tersified, $structure,
        q{Simple objects aren't affected});

    # But complex objects are tersified.
    my $complex_object
        = bless { id => TestObject->new(42) } => 'Complex::Object';
    $tersified = tersify($complex_object);
    like(
        ${ $tersified->{id} },
        qr{^ TestObject \s $re_refaddr \s ID \s 42 $}x,
        'The ID inside this object was tersified'
    );
    is(
        ref($tersified),
        'Data::Tersify::Summary::Complex::Object::0x'
            . refaddr($complex_object),
        'The original type and the refaddr of the object are mentioned'
    );
}

sub test_avoid_infinite_loops {
    my %babe;
    $babe{'The babe with the power'} = {
        'What power?' => {
            'The power of voodoo' => {
                'Voodoo?' => {
                    'You do' => {
                        'I do what?' => {
                            'Remind me of the babe' => {
                                'What babe?' => \%babe
                            }
                        }
                    }
                }
            }
        }
    };
    my %dialogue = (
        'You remind me of the babe' => {
            'What babe?' => \%babe,
        }
    );
    my $terse_dialogue = tersify(\%dialogue);
    is_deeply($terse_dialogue, \%dialogue,
        q{We aren't trapped by infinite loops});

    my $parts = bless { dialogue => \%dialogue, babe => \%babe } => 'Parts';
    my $terse_parts = tersify($parts);
    is_deeply($terse_parts, $parts,
        'This applies to blessed objects as well');
}

sub test_stringification {
    # We recognise objects that overload stringification.
    my $overloaded_no_params = TestObject::Overloaded->new;
    my %data = ( overloaded => $overloaded_no_params );
    my $tersified = tersify(\%data);
    like(
        ${ $tersified->{overloaded} },
        qr{^ TestObject::Overloaded \s $re_refaddr \s 
            \QAn object which was passed nothing\E $}x,
        'We recognise objects that support overloading...'
    );
    $data{overloaded} = TestObject::Overloaded->new('a herring');
    $tersified = tersify(\%data);
    like(
        ${ $tersified->{overloaded} },
        qr{^ TestObject::Overloaded \s $re_refaddr \s 
            \QAn object which was passed a herring\E $}x,
        '...no matter their contents'
    );

    # We won't stringify objects that overload other operations.
    $data{overloaded} = TestObject::Overloaded::OtherOperator->new;
    $tersified = tersify(\%data);
    is(refaddr($tersified->{overloaded}), refaddr($data{overloaded}),
        'An object that overloads, but not stringification, is not affected'
    );
    $data{overloaded} = TestObject::Overloaded::JustImport->new;
    $tersified = tersify(\%data);
    is(refaddr($tersified->{overloaded}), refaddr($data{overloaded}),
        'An object that just imports overload is not affected either'
    );
}

