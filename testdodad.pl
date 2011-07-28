#!/usr/bin/perl
use warnings;
use strict;
use 5.10.0;
use Data::Dump::Streamer 'Dumper', 'Dump';
use Java::Bridge;
$|=1;

my $bridge = Java::Bridge->new;

$bridge->setup_class('java.lang.Boolean');
print Java::Bridge::java::lang::Boolean::TRUE(), "\n";
