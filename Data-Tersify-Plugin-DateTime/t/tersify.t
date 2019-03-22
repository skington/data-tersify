#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Test::More;

use Data::Tersify qw(tersify);

test_datetime();

done_testing();

sub test_datetime {
    my $just_date = DateTime->new(year => 2017, month => 8, day => 17);
    my $full = DateTime->new(
        year   => 2017,
        month  => 8,
        day    => 17,
        hour   => 15,
        minute => 9,
        second => 23
    );
    (my $full_tz      = $full->clone())->set_time_zone('Europe/London');
    (my $just_date_tz = $just_date->clone())->set_time_zone('Europe/London');

    my $re_refaddr = qr{ \( 0x [0-9a-f]+ \) }x;
    my $original = {
        day           => $just_date,
        exact_time    => $full,
        day_tz        => $just_date_tz,
        exact_time_tz => $full_tz,
    };
    my $tersified = tersify($original);
    like(
        ${ $tersified->{day} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 $}x,
        'A DateTime with just day components is summarised as ymd'
    );
    like(
        ${ $tersified->{exact_time} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 \s 15:09:23$}x,
        'A fuller DateTime is summarised as ymd hms'
    );
    like(
        ${ $tersified->{day_tz} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 \s 00:00:00 \s Europe/London$}x,
        'A DateTime with just day components and a timezone is summarised as ymd 00:00:00 tz'
    );
    like(
        ${ $tersified->{exact_time_tz} },
        qr{^ DateTime \s $re_refaddr \s 2017-08-17 \s 15:09:23 \s Europe/London$}x,
        'A fuller DateTime with timezone is summarised as ymd hms tz'
    );
}
