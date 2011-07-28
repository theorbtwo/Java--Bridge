#!/usr/bin/perl
use warnings;
use strict;
use 5.10.0;
use Data::Dump::Streamer 'Dumper', 'Dump';
use Java::Bridge;
$|=1;

my $bridge = Java::Bridge->new;
$bridge->setup_class('java.lang.System');
my $props = Java::Bridge::java::lang::System->getProperties;
print "props: $props\n";

# http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4852768



