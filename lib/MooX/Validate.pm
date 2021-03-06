# ABSTRACT: Minimalist Data Validation for Moo

package MooX::Validate;

use utf8;
use strict;
use warnings;

use Validation::Class::Simple;

our $VERSION = '0.000003'; # VERSION

our %MAKERS = (); # this is meant to be pithy, mst--
our @ISA    = qw(Exporter);
our @EXPORT = qw(has);

sub import {

    my $class  = shift;
    my $target = caller;
    my $maker  = $MAKERS{$target} = {};

    if (my $has = $target->can('has')) {

        no strict   'refs';
        no warnings 'redefine';

        *{"$target\::has"} = sub {

            my ($name, %config) = @_;

            my $validation = delete $config{'validate'};

            my $build_coercion = 1 if
                !$config{'coerce'} &&
                (($validation and "HASH" eq ref $validation) and
                exists $validation->{filters})
            ;

            my $build_validation = 1 if
                !$config{'isa'} &&
                ($validation and "HASH" eq ref $validation)
            ;

            if ($build_coercion) {

                $config{'coerce'} = sub {

                    my  $parameter  = @_ > 2 ? [@_] : $_[0];
                    my  $validator  = Validation::Class::Simple->new(
                            report_failure => 1,
                            report_unknown => 1,
                            ignore_failure => 0,
                            ignore_unknown => 0,
                        );

                    $validator->fields->add($name, $validation);
                    $validator->params->add($name, $parameter);
                    $validator->prototype->normalize($validator);
                    $validator->params->get($name);

                };

            }

            if ($build_validation) {

                $config{'isa'} = sub {

                    my  $parameter  = @_ > 2 ? [@_] : $_[0];
                    my  $validator  = Validation::Class::Simple->new(
                            report_failure => 1,
                            report_unknown => 1,
                            ignore_failure => 0,
                            ignore_unknown => 0,
                        );

                    $validator->fields->add($name, $validation);
                    $validator->params->add($name, $parameter);

                    die $validator->errors_to_string
                        unless $validator->validate($name);

                    # defer
                    $maker->{$name} =
                        {rules => $validation, params => $parameter}
                    ;

                };

            }

            return $has->($name, %config);

        };

    }

    unless ($target->can('validator')) {

        no strict   'refs';
        no warnings 'redefine';

        *{"$target\::validator"} = sub {

            my $self = shift;

            my $class = ref $self;

            my $validator = Validation::Class::Simple->new(
                    report_failure => 1,
                    report_unknown => 1,
                    ignore_failure => 0,
                    ignore_unknown => 0,
                );

            while (my($name, $config) = each(%{$maker})) {

                my $validation = $config->{rules};
                my $parameter  = $config->{params};

                $validator->fields->add($name, $validation);
                $validator->params->add($name, $parameter);

            }

            return $validator;

        };

    }

    return;

}



1;

__END__

=pod

=head1 NAME

MooX::Validate - Minimalist Data Validation for Moo

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

    package Cat::Food;

    use Moo;
    use MooX::Validate;

    has brand => (
        is  => 'ro',
        validate => {
            options => ['SWEET-TREATZ', 'TREATZ-THATR-SWEET', 'NOM-NOMS'],
            filters => ['trim', 'strip'],
        }
    );

    has pounds => (
        is  => 'rw',
        validate => {
            error     => "less than 15 pounds, are you nuts?",
            filters   => ['trim','strip', 'numeric'],
            min_sum   => 15,
        }
    );

    package main;

    my  $food = Cat::Food->new(brand => 'NOM-NOMS', pounds => 20);

        $food->pounds('  p1oy5 '); # YIPPEE
        $food->pounds(10);         # KABOOM

    1;

=head1 DESCRIPTION

MooX::Validate is mashup between L<Validation::Class::Simple>, a wrapper around
the L<Validation::Class> library, which provides minimalist validation and
filtering automation, and L<Moo>. Validation::Class is a robust data validation
library that ships with a complete set of pre-defined validations and filters
referred to as L<directives|Validation::Class::Directives/DIRECTIVES>. Moo is an
extremely light-weight subset of L<Moose> optimised for rapid startup and
"pay only for what you use". It also avoids depending on any XS modules to allow
simple deployments. The name C<Moo> is based on the idea that it provides almost
but not quite two thirds of L<Moose>.

=head1 METHODS

=head2 validator

The validator method gives you access to a Validation::Class::Simple object
using the pre-declared validation rules defined in the attribute declarations.
See L<Validation::Class::Simple> for more information on utilizing this object.

    my  $validator = $self->validator;

        $validator->validate(@specifically);

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
