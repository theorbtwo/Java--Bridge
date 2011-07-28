#!/bin/env perl
# -*- cperl -*-
use warnings;
use strict;
use Test::More;

eval {
  require Test::Kwalitee; 
  Test::Kwalitee->import(tests => [qw< -has_readme >]);
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
