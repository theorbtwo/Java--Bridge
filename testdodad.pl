#!/usr/bin/perl
use warnings;
use strict;
use 5.10.0;
use Data::Dump::Streamer 'Dumper', 'Dump';
use Java::Bridge;
$|=1;

my $bridge = Java::Bridge->new;
$bridge->setup_class('java.lang.System');
my $out = Java::Bridge::java::lang::System::err();
say Java::Bridge::java::lang::System->getProperty("thispropertydoesnotexist", "thevalueofthenonexistantproperty");
