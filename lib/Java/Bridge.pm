package Java::Bridge;
use warnings;
use strict;
use Scalar::Util 'weaken';
use IPC::Run 'new_chunker';
use Class::MOP;
use Java::Bridge::java::lang::Object;

my $global_self;

sub new {
  my ($class) = @_;

  my $self = bless {}, $class;
  
  if ($global_self) {
    warn "Two bridges at once is ill-supported";
  } else {
    $global_self = $self;
  }

  $self->{in_string} = '';
  $self->{harness} = IPC::Run::harness(['java',
                                        -classpath => 'bin',
                                        'uk.me.desert_island.theorbtwo.bridge.Main'
                                       ],
                                       '<',  \$self->{in_string},
                                       '>',  new_chunker("\n"), sub {$self->stdout_handler(@_)},
                                       '2>', new_chunker("\n"), sub {$self->stderr_handler(@_)}
                                      );
  $self->{is_ready} = 0;
  
  while (!$self->{is_ready}) {
    $self->{harness}->pump;
  }

  return $self;
}

sub create {
  my ($self, $java_class) = @_;

  if (@_ > 2) {
    die "Non-default constructors not yet handled";
  }

  $self->{in_string} .= "create $java_class\n";

  delete $self->{return};
  while (!exists $self->{return}) {
    $self->{harness}->pump;
  }
  
  return $self->{return};
}

# END {
#   my $self = $global_self;
#   # This should get DESTROYed after all bridged objects on it do, but that's OK, it will, since the bridged objects
#   # have a hashref with a reference to us.  Our references to them, OTOH, are weak.

#   return if $self->{ready_for_suicide};

#   $self->{in_string} = "SHUTDOWN\n";
#   while (!$self->{ready_for_suicide}) {
#     $self->{harness}->pump;
#   }
# }

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

  if ($line eq 'Ready') {
    $self->{is_ready} = 1;
  } elsif ($line =~ m/^([a-z][A-Za-z0-9.\$]*>[0-9a-f]+)$/) {
    $self->{return} = $self->objectify($1);
  } elsif ($line eq 'DESTROYed') {
    $self->{destroyed} = 1;
  } elsif ($line =~ m/^call_method return: ([a-z][A-Za-z0-9.\$]*>[0-9a-f]+)$/) {
    $self->{ret} = $self->objectify($1);
  } elsif ($line =~ m/^call_static_method return: ([a-z][A-Za-z0-9.\$]*>[0-9a-f]+)$/) {
    $self->{ret} = $self->objectify($1);
  } elsif ($line =~ m/^dump_string: '(.*)'$/) {
    $self->{ret} = $1;
    $self->{ret} =~ s/\\n/\n/g;
    $self->{ret} =~ s/\\(.)/$1/g;
  } elsif ($line =~ m/^thrown: (.*)$/) {
    die $1;
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

  warn "setup_class $java_name -> $perl_class";

  Class::MOP::Class->create(
                            $perl_class,
                            # We need someplace to stick our wierd
                            # stuff.  This is as good as any, and
                            # better then many.
                            superclasses => [ 'Java::Bridge::java::lang::Object' ],
                            methods => {
                                        _static_bridge => sub {$bridge},
                                        _java_name => sub {$java_name},
                                       }
                           );

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

  if (exists $bridge->{known_objects}{$obj_ident} and
      $bridge->{known_objects}{$obj_ident}
     ) {
    # Note the lack of "exists" -- a weak ref that got DESTROYed will
    # keep an entry in the hash, with undef.  Could use exists to keep
    # the hash from growing due to the test autovivifying, but we're
    # about to add it to the hash anyway.
    # This comment is probably far longer then it deserves to be.
    return $bridge->{known_objects}{$obj_ident};
  }

  my ($java_class, $hash_code) = ($obj_ident =~ m/^([a-z][A-Za-z0-9.\$]*)>([0-9a-f]+)$/);

  my $perl_class = $bridge->setup_class($java_class);

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
  $self->{in_string} .= "DESTROY $obj_ident\n";
  
  delete $self->{destroyed};
  while (!$self->{destroyed}) {
    $self->{harness}->pump;
  }
  delete $self->{destroyed};
}

sub stderr_handler {
  my ($self, $line) = @_;
  chomp $line;

  print STDERR "(From across bridge): $line\n";
}

sub call_method {
  my ($self, $obj_ident, $name) = @_;

  $self->{in_string} .= "call_method $obj_ident $name\n";

  delete $self->{ret};
  while (!$self->{ret}) {
    $self->{harness}->pump;
  }

  return $self->{ret};
}

sub call_static_method {
  my ($self, $class, $name) = @_;

  $self->{in_string} .= "call_static_method $class $name\n";

  delete $self->{ret};
  while (!$self->{ret}) {
    $self->{harness}->pump;
  }

  return $self->{ret};
}

sub dump_string {
  my ($self, $obj_ident) = @_;

  $self->{in_string} .= "dump_string $obj_ident\n";

  delete $self->{ret};
  while (!$self->{ret}) {
    $self->{harness}->pump;
  }

  return $self->{ret};
}

'a series of tubes';
