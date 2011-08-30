package Java::Bridge::TieHashForFields;
use warnings;
use strict;
no overloading;

sub TIEHASH {
  my ($classname, $obj) = @_;

  my $self = bless {java_object => $obj}, $classname;
}

sub FETCH {
  my ($self, $key) = @_;

#  warn "Fetching field $key from ".join(' -- ', caller(1));

  no overloading '%{}';
  $self->{java_object}->{bridge}->fetch_field($self->{java_object}, $key);
}

'aaaargh';
