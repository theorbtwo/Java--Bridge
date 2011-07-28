#!/usr/bin/perl
use warnings;
use strict;
use 5.10.0;
use Data::Dump::Streamer 'Dumper';

# plural, type
my $reflection_meta = {
		       'annotation'
		       => {
			   toString => [0, 'string'],
			   annotationType => [0, 'class'],
			   hashCode => [0, 'string'],
			  },

		       'class'
		       => {
			   desiredAssertionStatus  => [0, 'boolean'],
			   getCannonicalName       => [0, 'string'],
			   getDeclaredConstructors => [1, 'constructor'],
			   getDeclaredClasses      => [1, 'class'      ],
			   getDeclaredFields       => [1, 'field'      ],
			   getConstructors         => [1, 'constructor'],
			   getClasses              => [1, 'class'],
			   getAnnotations          => [1, 'annotation'],
			   getDeclaredAnnotations  => [1, 'annotation'],
                           getComponentType        => [1, 'class'],
			  },

		       'constructor'
		       => {
			   getDeclaringClass => [0, 'class'],
			   getName => [0, 'string'],
			   toString => [0, 'string'],
			   toGenericString => [0, 'string'],
			   getAnnotations => [1, 'annotation'],
			   getExceptionTypes => [1, 'class'],
			   getParameterTypes => [1, 'class'],
			  },

		       'field'
		       => {
			   getModifiers => [0, 'string'],
			   getName      => [0, 'string'],
			   getType      => [0, 'class' ],
			   get => [0, 'string'],
			  }
		      };

my $reflected;
while (<>) {
  if (m/^Skipping duplicate dump of/) {
    next;
  }

  my ($type, $hash, $middle, $end) = m/^([a-z]+) ([0-9a-f]+): (.*?): (.*)$/
    or die "Couldn't parse line $_ ";
  
  $reflected->{$type}{$hash} ||= {};
  my $it = $reflected->{$type}{$hash};

  if (!$reflection_meta->{$type}) {
    die "No reflection metadata for type $type";
  }

  if (!$reflection_meta->{$type}{$middle}) {
    die "No reflection metadata for middle $middle of type $type";
  }

  my $metatype = $reflection_meta->{$type}{$middle}[1];
  if ($metatype eq 'boolean') {
    $end = $end eq 'true';
  } elsif ($metatype eq 'string') {
    # do nothing.
  } elsif ($metatype ~~ ['constructor', 'class', 'field', 'annotation']) {
    $reflected->{$metatype}{$end} ||= {};
    $end = $reflected->{$metatype}{$end};
  } else {
    die "Unknown metatype $metatype";
  }
  
  if ($reflection_meta->{$type}{$middle}[0]) {
    push @{$reflected->{$type}{$hash}{$middle}}, $end;
  } else {
    $reflected->{$type}{$hash}{$middle} = $end;
  }

  if ($type eq 'class' and $middle eq 'getCannonicalName') {
    $reflected->{class_by_name}{$end} = $reflected->{$type}{$hash};
  }
}

final_dump($reflected);

sub final_dump {
  my ($reflected) = @_;

  my $dump = Dumper($reflected->{class_by_name});
  $dump =~ s/^\$HASH1->.*?\n//mg;
  print $dump;
}
