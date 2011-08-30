package Java::Bridge::java::lang::Boolean;
use warnings;
use strict;
use overload 'bool' => sub {
  my ($self) = @_;
  
  "$self" eq 'true';
};

'Fourty-two';
