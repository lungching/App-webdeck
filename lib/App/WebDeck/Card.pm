
class App::WebDeck::Card {

=head1 NAME

App::WebDeck::Card - A single card

=head1 DESCRIPTION

Each card has it's own state -- where it is on the table, whether it is face-up or face-down, and a unique ID that can be used by users to refer to the card. Also whether or not someone is holding the card.

Dev-note: Each card should get it's own UUID. This UUID would be changed whenever we need to obscure which card it is. This would certainly happen whenever a set of cards is shuffled. It should also happen after every operation in a person's hand I think, among all the cards in the hand. Otherwise other players might be able to "peek", tracking the card as it stays in the first player's hand. Food for thought.

=cut

use Moose::Util::TypeConstraints;
use UUID::Tiny ':std';

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

has id => (
  is      => 'rw',
  isa     => 'Str',
  default => sub { create_uuid_as_string(UUID_V4) },
);

method reset_uuid {
  $self->id( create_uuid_as_string(UUID_V4) );
}

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

