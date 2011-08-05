#!/usr/bin/perl
use warnings;
use strict;
use Java::Bridge;
use 5.10.0;

my $bridge = Java::Bridge->new;

$bridge->setup_class('java.lang.Boolean');

my $true = Java::Bridge::java::lang::Boolean::TRUE();
my $false = Java::Bridge::java::lang::Boolean::FALSE();

$bridge->setup_class('javax.swing.JFrame');
*JFrame:: = *Java::Bridge::javax::swing::JFrame::;

$bridge->setup_class('java.lang.Class');
my $jframe_class = Java::Bridge::java::lang::Class->forName('javax.swing.JFrame');

for my $meth (@{$jframe_class->getMethods}) {
  print "Method: $meth\n";
}


exit;

Java::Bridge::javax::swing::JFrame->setDefaultLookAndFeelDecorated($true);
my $frame = $bridge->create('javax.swing.JFrame', 'HelloWorldSwing');
$frame->setDefaultCloseOperation(Java::Bridge::javax::swing::JFrame::EXIT_ON_CLOSE());

$bridge->setup_class('javax.swing.JLabel');
my $label = Java::Bridge::javax::swing::JLabel->new("Hello World");
$frame->getContentPane->add($label);

$frame->pack;
$frame->setVisble($true);