#!/bin/env perl
# -*- cperl -*-
use warnings;
use strict;
use Test::More;

eval {
  require Test::Kwalitee; 
  Test::Kwalitee->import(tests => [# I do not believe in README files in CPAN distros.
                                   # either they duplicate the POD, or they contain
                                   # information most people will never see, that
                                   # should be in the POD.
                                   '-has_readme',
                                   # These should be created later rather then sooner.
                                   '-has_meta_yml', '-has_manifest',
                                  ]);
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
