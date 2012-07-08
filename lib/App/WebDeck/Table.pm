
class App::WebDeck::Table {

=head1 NAME

App::WebDeck::Table - Holds the elements of a game

=head1 DESCRIPTION

The idea here is to represent the actual table that you are sitting down and playing a game on. So it holds the cards, and eventually the stack of cards. It should have an idea of what players there are.

=cut

use App::WebDeck::Card;
use Data::Printer;
use List::Util qw( shuffle );

has cards => (
  is      => 'rw',
  isa     => 'ArrayRef[App::WebDeck::Card]',
  default => sub { [] },
);

has players => (
  is      => 'rw',
  isa     => 'ArrayRef[App::WebDeck::User]',
  default => sub { [] },
);

has cardmove_watcher => (
  is      => 'rw',
  isa     => 'ArrayRef',
  default => sub { [] },
);

has deck_path => (
  is  => 'rw',
  isa => 'Str',
);

method BUILD {
  my $deck_path = $self->deck_path;
  say STDERR "Looking at ls $deck_path/card*.png";
  my @card_paths = `ls $deck_path/card*.png`;
  @card_paths = map { chomp ; $_ } @card_paths;
  @card_paths = map { s/.*\/// ; $_ } @card_paths;
  say "Card files: " . p(@card_paths);
  @card_paths = shuffle @card_paths;
  my $deck = [ map {
    App::WebDeck::Card->new(
      back_img => 'back.png',
      face_img => $_,
    )
  } @card_paths ];
  p $deck;
  $self->cards($deck);
}

method get_card_by_id($id) {
  my ($card) = grep { $_->id eq $id } @{ $self->cards };
  return $card;
}

method add_cardmove_watcher($watcher) {
  push @{ $self->cardmove_watcher }, $watcher;
}

method move_card(:$card_id, :$x, :$y, :$z) {
  my $card = $self->get_card_by_id($card_id);

  # Set our new position
  $card->position([$x, $y, $z]);

  # Notify all listeners that we have done a move
  say "sending all notifications";
  while(my $watcher = shift @{ $self->cardmove_watcher }) {
    say "Notifying...";
    # $watcher->send($card);
    $watcher->send($card, 'movecard');
  }
}

method flip_card(:$card_id) {
  my $card = $self->get_card_by_id($card_id);

  $card->switch_orientation();

  # Notify all listeners that we have done a move
  while(my $watcher = shift @{ $self->cardmove_watcher }) {
    $watcher->send($card, 'flipcard');
  }
}


}

