#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib/06';

sub warnings_ok {
    my ($class, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    use_ok($class);
    is($warnings, $expected, "correct runtime warnings for $class");
}

warnings_ok('Foo', <<'WARNINGS');
Conflict detected for Foo::Conflicts:
  Foo::Foo is version 0.01, but must be greater than version 0.01
Conflict detected for Foo::Conflicts:
  Foo::Bar is version 0.01, but must be greater than version 0.01
WARNINGS
warnings_ok('Bar', <<'WARNINGS');
Conflict detected for Bar::Conflicts:
  Bar::Baz::Bad is version 0.01, but must be greater than version 0.01
Conflict detected for Bar::Conflicts:
  Bar::Foo::Bad is version 0.01, but must be greater than version 0.01
Conflict detected for Bar::Conflicts:
  Bar::Foo is version 0.01, but must be greater than version 0.01
Conflict detected for Bar::Conflicts:
  Bar::Bar::Bad is version 0.01, but must be greater than version 0.01
Conflict detected for Bar::Conflicts:
  Bar::Bar is version 0.01, but must be greater than version 0.01
Conflict detected for Bar::Conflicts:
  Bar::Quux::Bad is version 0.01, but must be greater than version 0.01
WARNINGS

is(scalar(grep { ref($_) eq 'ARRAY' && @$_ > 1 && ref($_->[1]) eq 'HASH' }
               @INC),
   1,
   "only installed one \@INC hook");

done_testing;
