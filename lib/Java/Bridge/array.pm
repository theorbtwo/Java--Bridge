package Java::Bridge::array;
use warnings;
use strict;
use base 'Java::Bridge::java::lang::Object', 'Tie::Array';
use overload
  '@{}' => sub {
    my ($self) = @_;

    tie my @ret, ref $self, $self;

    return \@ret;
  };

sub TIEARRAY {
  my ($class, $self) = @_;
  
  return $self;
}

sub FETCHSIZE {
  my ($self) = @_;

  # FIXME: why does this not work?
  #$self->{bridge}->fetch_field($self->{obj_ident}, 'length');
  $self->{bridge}->get_array_length($self->{obj_ident});
}

sub FETCH {
  my ($self, $index) = @_;
  
  $self->{bridge}->fetch_array_element($self->{obj_ident}, $index);
}

sub STORE {
  my ($self, $index, $value) = @_;

  $self->{bridge}->store_array_element($self->{obj_ident}, $index);
}

'This sentence is false';
