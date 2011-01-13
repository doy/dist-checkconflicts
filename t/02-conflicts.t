#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/lib/02';

sub use_ok_warnings {
    my ($class, @conflicts) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    @conflicts = sort map { "Conflict detected for $_->[0]:\n  $_->[1] is version $_->[2], but must be greater than version $_->[3]\n" } @conflicts;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        use_ok($class);
    }
    @warnings = sort @warnings;

    is_deeply(\@warnings, \@conflicts, "correct runtime warnings for $class");
}

{
    use_ok('Foo::Conflicts::Good');
    is_deeply(
        [ Foo::Conflicts::Good->calculate_conflicts ],
        [],
        "correct versions for all conflicts",
    );
    is(
        exception { Foo::Conflicts::Good->check_conflicts },
        undef,
        "no conflict error"
    );
}

{
    use_ok_warnings(
        'Foo::Conflicts::Bad',
        ['Foo::Conflicts::Bad', 'Foo::Two', '0.02', '0.02'],
        ['Foo::Conflicts::Bad', 'Foo',      '0.02', '0.03'],
    );

    is_deeply(
        [ Foo::Conflicts::Bad->calculate_conflicts ],
        [
            { package => 'Foo',      installed => '0.02', required => '0.03' },
            { package => 'Foo::Two', installed => '0.02', required => '0.02' },
        ],
        "correct versions for all conflicts",
    );
    is(
        exception { Foo::Conflicts::Bad->check_conflicts },
        "Conflicts detected for Foo::Conflicts::Bad:\n  Foo is version 0.02, but must be greater than version 0.03\n  Foo::Two is version 0.02, but must be greater than version 0.02\n",
        "correct conflict error"
    );
}

{
    use_ok('Bar::Conflicts::Good');
    is_deeply(
        [ Bar::Conflicts::Good->calculate_conflicts ],
        [],
        "correct versions for all conflicts",
    );
    is(
        exception { Bar::Conflicts::Good->check_conflicts },
        undef,
        "no conflict error"
    );
}

{
    use_ok_warnings(
        'Bar::Conflicts::Bad',
        ['Bar::Conflicts::Bad2', 'Bar::Two', '0.02', '0.02'],
        ['Bar::Conflicts::Bad',  'Bar::Two', '0.02', '0.02'],
        ['Bar::Conflicts::Bad',  'Bar',      '0.02', '0.03'],
    );

    is_deeply(
        [ Bar::Conflicts::Bad->calculate_conflicts ],
        [
            { package => 'Bar',      installed => '0.02', required => '0.03' },
            { package => 'Bar::Two', installed => '0.02', required => '0.02' },
        ],
        "correct versions for all conflicts",
    );
    is(
        exception { Bar::Conflicts::Bad->check_conflicts },
        "Conflicts detected for Bar::Conflicts::Bad:\n  Bar is version 0.02, but must be greater than version 0.03\n  Bar::Two is version 0.02, but must be greater than version 0.02\n",
        "correct conflict error"
    );
}

done_testing;
