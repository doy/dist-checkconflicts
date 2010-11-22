package Dist::CheckConflicts;
use strict;
use warnings;
# ABSTRACT: declare version conflicts for your dist

use Carp;
use List::MoreUtils 'first_index';
use Sub::Exporter;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

my $import = Sub::Exporter::build_exporter({
    exports => [ qw(conflicts check_conflicts calculate_conflicts dist) ],
    groups => {
        default => [ qw(conflicts check_conflicts calculate_conflicts dist) ],
    },
});

my %CONFLICTS;
my %DISTS;

sub import {
    my $for = caller;

    my ($conflicts, $alsos, $dist);
    ($conflicts, @_) = _strip_opt('-conflicts' => @_);
    ($alsos, @_)     = _strip_opt('-also' => @_);
    ($dist, @_)      = _strip_opt('-dist' => @_);

    my %conflicts = %{ $conflicts || {} };
    for my $also (@{ $alsos || [] }) {
        eval "require $also; 1;" or die "Couldn't find package $also: $@";
        my %also_confs = $also->conflicts;
        for my $also_conf (keys %also_confs) {
            $conflicts{$also_conf} = $also_confs{$also_conf}
                if !exists $conflicts{$also_conf}
                || $conflicts{$also_conf} lt $also_confs{$also_conf};
        }
    }

    $CONFLICTS{$for} = \%conflicts;
    $DISTS{$for}     = $dist || $for;

    goto $import;
}

sub _strip_opt {
    my $opt = shift;
    my $idx = first_index { ( $_ || '' ) eq $opt } @_;

    return ( undef, @_ ) unless $idx >= 0 && $#_ >= $idx + 1;

    my $val = $_[ $idx + 1 ];

    splice @_, $idx, 2;

    return ( $val, @_ );
}

=method conflicts

=cut

sub conflicts {
    my $package = shift;
    return %{ $CONFLICTS{ $package } };
}

=method dist

=cut

sub dist {
    my $package = shift;
    return $DISTS{ $package };
}

=method check_conflicts

=cut

sub check_conflicts {
    my $package = shift;
    my $dist = $package->dist;
    my @conflicts = $package->calculate_conflicts;
    return unless @conflicts;

    my $err = "Conflicts detected for $dist:\n";
    for my $conflict (@conflicts) {
        $err .= "  $conflict->{package} is version "
                . "$conflict->{installed}, but must be greater than version "
                . "$conflict->{required}\n";
    }
    die $err;
}

=method calculate_conflicts

=cut

sub calculate_conflicts {
    my $package = shift;
    my %conflicts = $package->conflicts;

    my @ret;

    CONFLICT:
    for my $conflict (keys %conflicts) {
        {
            local $SIG{__WARN__} = sub { };
            eval "require $conflict; 1" or next CONFLICT;
        }
        my $installed = $conflict->VERSION;
        push @ret, {
            package   => $conflict,
            installed => $installed,
            required  => $conflicts{$conflict},
        } if $installed le $conflicts{$conflict};
    }

    return sort { $a->{package} cmp $b->{package} } @ret;
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-dist-checkconflicts at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-CheckConflicts>.

=head1 SEE ALSO

=over 4

=item * L<Module::Install::CheckConflicts>

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Dist::CheckConflicts

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-CheckConflicts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-CheckConflicts>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-CheckConflicts>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-CheckConflicts>

=back

=cut

1;
