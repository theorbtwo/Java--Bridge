#!/usr/bin/perl
use warnings;
use strict;
use Java::Bridge;
use 5.10.0;

my $bridge = Java::Bridge->new;

$bridge->setup_class('java.lang.Boolean');

my $true = Java::Bridge::java::lang::Boolean::TRUE();
my $false = Java::Bridge::java::lang::Boolean::FALSE();

Java::Bridge::javax::swing::JFrame->setDefaultLookAndFeelDecorated($true);
my $frame = $bridge->create('javax.swing.JFrame'); #, 'HelloWorldSwing');
$frame->setDefaultCloseOperation(Java::Bridge::javax::swing::JFrame::EXIT_ON_CLOSE());

$bridge->setup_class('javax.swing.JLabel');
my $label = $bridge->create('javax.swing.JLabel');
$frame->getContentPane->add($label);

$frame->pack;
$frame->setVisible($true);

while (1) {
  print "sleeping 5\n";
  sleep 5;
}
