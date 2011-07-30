#!/bin/env perl
# -*- cperl -*-
use warnings;
use strict;
use Test::More;
use Java::Bridge;
use Cwd;

my $bridge = Java::Bridge->new;
is(ref($bridge), 'Java::Bridge');
my $class = $bridge->setup_class('java.lang.System');
is($class, 'Java::Bridge::java::lang::System');
my $props = Java::Bridge::java::lang::System->getProperties;
my $cwd = getcwd;
is($props =~ m!user\.dir=\Q$cwd\E,!, 1);



is($bridge->create('java.lang.Exception') . "", 'java.lang.Exception');


$bridge->setup_class('java.lang.Boolean');
is(Java::Bridge::java::lang::Boolean::TRUE() . "", 'true');


done_testing;
