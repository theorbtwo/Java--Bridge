package Java::Bridge;
use warnings;
use strict;

BEGIN {
  our $VERSION = 0.01;
}

use Scalar::Util 'weaken', 'looks_like_number';
use IPC::Run 'new_chunker';
#use Class::MOP;
use Java::Bridge::java::lang::Object;
use Java::Bridge::array;


my $global_self;

my $obj_ident_re = qr/null|\[*L?[a-z][A-Za-z0-9.\$]*;*>[0-9a-f]+/;

sub new {
  my ($class) = @_;

  my $self = bless {}, $class;
  
  if ($global_self) {
    warn "Two bridges at once is ill-supported";
  } else {
    $global_self = $self;
  }

  $self->{in_string} = '';
  if ($^O eq 'android') {
    $self->{harness} = IPC::Run::harness(['dalvikvm',
                                          -classpath => 'bridge.dex',
                                          'uk.me.desert_island.theorbtwo.bridge.Main'
                                         ],
                                         '<',  \$self->{in_string},
                                         '>',  new_chunker("\n"), sub {$self->stdout_handler(@_)},
                                         '2>', new_chunker("\n"), sub {$self->stderr_handler(@_)}
                                        );
  } else {
    $self->{harness} = IPC::Run::harness(['java',
                                          -classpath => 'bin',
                                          'uk.me.desert_island.theorbtwo.bridge.Main'
                                         ],
                                         '<',  \$self->{in_string},
                                         '>',  new_chunker("\n"), sub {$self->stdout_handler(@_)},
                                         '2>', new_chunker("\n"), sub {$self->stderr_handler(@_)}
                                        );
  }
  $self->{is_ready} = 0;
  while (!$self->{is_ready}) {
    $self->{harness}->pump;
  }

  return $self;
}

sub send_and_wait {
  my ($self, $command) = @_;


  $command .= "\n"
    unless $command =~ m/\n$/;

  my $command_id = ++$self->{command_id};
  
  $command = "$command_id $command";

  print "send_and_wait sending $command";

  $self->{in_string} .= $command;

  while (!exists $self->{replies}{$command_id}) {
    $self->{harness}->pump;

    if (exists $self->{error_replies}{$command_id}) {
      die delete $self->{error_replies}{$command_id};
    }
  }

  return delete $self->{replies}{$command_id};
}

sub create {
  my ($self, $java_class) = @_;

  if (@_ > 2) {
    die "Non-default constructors not yet handled";
  }

  $self->send_and_wait("create $java_class\n");
}

END {
  my $self = $global_self;
  # This should get DESTROYed after all bridged objects on it do, but that's OK, it will, since the bridged objects
  # have a hashref with a reference to us.  Our references to them, OTOH, are weak.

  return if $self->{ready_for_suicide};
  
  $self->send_and_wait('SHUTDOWN');

  $self->{ready_for_suicide}++;

  $self->{harness}->finish;
}

#sub DESTROY {
#  my ($self) = @_;
#
#  if (!$self->{ready_for_suicide}) {
#    warn "In DESTROY without END?";
#  }
#}

sub stdout_handler {
  my ($self, $line) = @_;
  chomp $line;

  print "stdout_handler: '$line'\n";

  if ($line eq 'Ready') {
    $self->{is_ready} = 1;
  } elsif ($line =~ m/^(\d+) ($obj_ident_re)$/) {
    $self->{replies}{$1} = $self->objectify($2);
  } elsif ($line =~ m/^(\d+) DESTROYed$/) {
    $self->{replies}{$1} = 1;
  } elsif ($line =~ m/^(\d+) SHUTDOWN$/) {
    $self->{replies}{$1} = 1;
  } elsif ($line =~ m/^(\d+) call_method return: ($obj_ident_re)$/) {
    $self->{replies}{$1} = $self->objectify($2);
  } elsif ($line =~ m/^(\d+) call_static_method return: ($obj_ident_re)$/) {
    $self->{replies}{$1} = $self->objectify($2);
  } elsif ($line =~ m/^(\d+) fetch_static_field return: ($obj_ident_re)$/) {
    $self->{replies}{$1} = $self->objectify($2);
  } elsif ($line =~ m/^(\d+) num return: (\d+)$/) {
    $self->{replies}{$1} = $2;
  } elsif ($line =~ m/^(\d+) dump_string: '(.*)'$/) {
    my ($command_id, $ret) = ($1, $2);
    $ret =~ s/\\n/\n/g;
    $ret =~ s/\\(.)/$1/g;
    $self->{replies}{$command_id} = $ret;
  } elsif ($line =~ m/^(\d+) thrown: (.*)$/) {
    $self->{error_replies}{$1} = $2;
  } else {
    print "Got unhandled stuff from subprocess: '$line'\n";
  }
}

sub java_name_to_perl_name {
  my ($java_name) = @_;
  $java_name =~ s/\./::/g;
  $java_name =~ s/\$/::/g;
  return "Java::Bridge::$java_name";
}

sub setup_class {
  my ($bridge, $java_name) = @_;

  my $perl_class = java_name_to_perl_name($java_name);

  {
    no strict 'refs';
    return $perl_class if @{"$perl_class\::ISA"};
  }

  # warn "setup_class $java_name -> $perl_class";

#  Class::MOP::Class->create(
#                            $perl_class,
#                            # We need someplace to stick our wierd
#                            # stuff.  This is as good as any, and
#                            # better then many.
#                            superclasses => [ 'Java::Bridge::java::lang::Object' ],
#                            methods => {
#                                        _static_bridge => sub {$bridge},
#                                        _java_name => sub {$java_name},
#                                       }
#                           );
  {
    no strict 'refs';
    @{"$perl_class\::ISA"} = 'Java::Bridge::java::lang::Object';
    *{"$perl_class\::_static_bridge"} = sub {$bridge};
    *{"$perl_class\::_java_name"} = sub {$java_name};
  }

  my $ret = eval "use $perl_class; 1;";
  my $e = $@;
  my $perl_class_for_error = $perl_class;
  $perl_class_for_error =~ s!::!/!g;
  $perl_class_for_error .= ".pm";
  $perl_class_for_error = qr/Can't locate \Q$perl_class_for_error\E/;
  if (!$ret and $e !~ $perl_class_for_error) {
    print "$e !~ $perl_class_for_error\n";
    die $e;
    # do nothing
  }

  return $perl_class;
}

sub objectify {
  my ($bridge, $obj_ident) = @_;

  if ($obj_ident eq 'null') {
    return undef;
  }

  if (exists $bridge->{known_objects}{$obj_ident} and
      $bridge->{known_objects}{$obj_ident}
     ) {
    print "Reusing existing $obj_ident\n";
    return $bridge->{known_objects}{$obj_ident};
  }

  my ($java_class, $hash_code) = ($obj_ident =~ m/^(\[*L?[a-z][A-Za-z0-9.\$]*;*)>([0-9a-f]+)$/);

  my $perl_class;
  if ($java_class =~ m/^\[L(.*);$/) {
    $perl_class = 'Java::Bridge::array';
  } else {
    $perl_class = $bridge->setup_class($java_class);
  }
  
  my $obj = bless {}, $perl_class;
  $obj->{obj_ident} = $obj_ident;
  $obj->{hash_code} = $hash_code;
  $obj->{bridge} = $bridge;

  $bridge->{known_objects}{$obj_ident} = $obj;
  # anti-leak!
  weaken($bridge->{known_objects}{$obj_ident});
  
  return $obj;
}

sub destroy_object {
  my ($self, $obj_ident) = @_;

  delete $self->{known_objects}{$obj_ident};
  $self->send_and_wait("DESTROY $obj_ident\n");
}

sub stderr_handler {
  my ($self, $line) = @_;
  chomp $line;

  print STDERR "(From across bridge): $line\n";
}

sub make_string {
  my ($self, $str) = @_;

  $str =~ s/\\/\\\\/g;
  $str =~ s/ /\\x20/g;
  $str =~ s/\n/\\n/g;
  
  $self->send_and_wait("make_string $str");
}

sub magic_argument_to_java {
  my ($self, $perlish) = @_;
  my $temp;
  my $obj_ident;

  die "magic_argument_to_java must be called in list context"
    unless wantarray;

  if (not defined $perlish) {
    return ('null', undef);
  } elsif (ref $perlish and $perlish->isa('Java::Bridge::java::lang::Object')) {
    return ($perlish->{obj_ident}, undef);
  } elsif (not ref $perlish and not looks_like_number $perlish) {
    my $strobj = $self->make_string($perlish);
    return ($strobj->{obj_ident}, $strobj);
  } else {
    die "Don't know how to magically make $perlish into a java argument";
  }
}

sub call_method {
  my ($self, $obj_ident, $name, @args) = @_;

  # We need to hold on to a reference to the strings until after the send_and_wait
  # has finished, or they will be DESTROYed before they are sent off.
  my @holder;
  my @wire_args;

  for my $arg (@args) {
    my ($wire_arg, $holder) = $self->magic_argument_to_java($arg);
    push @wire_args, $wire_arg;
    push @holder, $holder;
  }

  my $wire_args = join ' ', @wire_args;

  $self->send_and_wait("call_method $obj_ident $name $wire_args\n");
}

sub call_static_method {
  my ($self, $class, $name, @args) = @_;

  # We need to hold on to a reference to the strings until after the send_and_wait
  # has finished, or they will be DESTROYed before they are sent off.
  my @holder;
  my @wire_args;

  for my $arg (@args) {
    my ($wire_arg, $holder) = $self->magic_argument_to_java($arg);
    push @wire_args, $wire_arg;
    push @holder, $holder;
  }

  my $wire_args = join ' ', @wire_args;

  $self->send_and_wait("call_static_method $class $name $wire_args\n");
}

sub fetch_static_field {
  my ($self, $class, $name) = @_;

  $self->send_and_wait("fetch_static_field $class $name\n");
}

sub fetch_field {
  my ($self, $obj_ident, $name) = @_;

  $self->send_and_wait("fetch_field $obj_ident $name\n");
}

sub get_array_length {
  my ($self, $obj_ident) = @_;

  $self->send_and_wait("get_array_length $obj_ident\n");
}

sub fetch_array_element {
  my ($self, $obj_ident, $index) = @_;

  $self->send_and_wait("fetch_array_element $obj_ident $index\n");
}

sub dump_string {
  my ($self, $obj_ident) = @_;

  $self->send_and_wait("dump_string $obj_ident\n");
}

'a series of tubes';
