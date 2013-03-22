use utf8;
use strict;
use warnings;
use Test::More;

{

    use_ok 'MooX::Validate';

}

{

    package TestClass;

    use Moo;
    use MooX::Validate;

    has 'today' => (
        is => 'rw',
        required => 1,
        validate => {
            date => 1,
            filters => ['trim', 'strip']
        }
    );

    package main;

    my $class;

    eval { $class = TestClass->new(today => "        1/1/1901") };

    ok "TestClass" eq ref $class, "TestClass instantiated; Date validated";
    ok $class->today !~ /\s/, "today's date is formatted properly";

    eval { $class->today(12345) };
    ok $@ =~ /valid date/, "failed to set date to 12345: isa check failed";

}

done_testing;
