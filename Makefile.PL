#!/bin/env perl
use warnings;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME => 'Java::Bridge',
              VERSION_FROM => 'lib/Java/Bridge.pm',
              PREREQ_PM => {
                            'IPC::Run' => 0
                           },
             );
