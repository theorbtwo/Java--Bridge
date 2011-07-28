package Java::Bridge::java::lang::String;
use warnings;
use strict;
use overload '""' => \&stringify;

sub stringify {
  my ($self) = @_;

  $self->{bridge}->dump_string($self->{obj_ident});
}

'how long is a piece of string?';
