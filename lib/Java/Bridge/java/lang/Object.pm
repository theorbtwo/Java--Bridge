package Java::Bridge::java::lang::Object;
use warnings;
use strict;
use overload ('""' => sub {$_[0]->toString},
              '%{}' => sub {
                my ($self) = @_;
                tie my %ret, 'Java::Bridge::TieHashForFields', $self;
                return \%ret;
              },

              #nomethod => \&nomethod,
              #fallback => 0,
              bool => sub{1},
             );
use Carp 'cluck';
use Java::Bridge::TieHashForFields;
no overloading '%{}';

sub DESTROY {
  my ($self) = @_;

  # cluck("Destroy");

  # While in global destroy, all bets are off, so make sure the bridge still exists.
  # I'd love a better way to fix this.
  no overloading;
  if ($self->{bridge}) {
    $self->{bridge}->destroy_object($self->{obj_ident});
  }
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  our $AUTOLOAD;

  no overloading;

  #if (@_ != 1) {
  #  die "Only methods without arguments supported (so far)";
  #}

  if (@_ == 0) {
    # Static field -- constant, normally.
    my ($class, $methname) = ($AUTOLOAD =~ m/^(.*)::(.*?)$/);

    return $class->_static_bridge->fetch_static_field($class->_java_name, $methname);
  }

  my $realclass = ref($self) || $self;
  my $classlen = length($realclass);
  my $substrclass = substr($AUTOLOAD, 0, $classlen);
  die "class clash in AUTOLOAD: $substrclass vs $realclass from $AUTOLOAD" if ($substrclass ne $realclass);
  
  my $methname = substr($AUTOLOAD, $classlen+2);
  
  if (not ref $self) {
    # static method (class method).

    $self->_static_bridge->call_static_method($self->_java_name, $methname, @args);
  } else {
    # non-static method (instance method).

    $self->{bridge}->call_method($self->{obj_ident}, $methname, @args);
  }
}


'It all begins here, the stench and the peril.';
