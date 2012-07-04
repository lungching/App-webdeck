
class App::WebDeck::Card {

use Moose::Util::TypeConstraints;

enum orientation => [qw( face_up face_down )];

has currentOrientation => (
  is      => 'rw',
  isa     => 'orientation',
  default => sub { 'face_down' },
);

# x,y,z coordinate of the card
has position => (
  is      => 'rw',
  isa     => 'ArrayRef[Int]',
  default => sub { [0,0,1] }, # z is 1 to start to be above drops
);

has currentHolder => (
  is      => 'rw',
  isa     => 'Maybe[App::WebDeck::User]', # or Player
  default => sub { undef },
);

has face_img => (
  is  => 'rw',
  isa => 'Str',
);

has back_img => (
  is  => 'rw',
  isa => 'Str',
);

# TODO: Switch to UUID
has id => (
  is  => 'rw',
  isa => 'Int',
);

method get_position {
  return @{ $self->position };
}

method to_hash {
  my ($x, $y, $z) = $self->get_position;
  return {
    x => $x,
    y => $y,
    z => $z,
    id => $self->id,
    orientation => $self->currentOrientation,
  };
}

}

