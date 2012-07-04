
class App::WebDeck::Table {

=head1 NAME

App::WebDeck::Table - Holds the elements of a game

=cut

use App::WebDeck::Card;

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

has deck_path => (
  is  => 'rw',
  isa => 'Str',
);

use Data::Printer;
method BUILD {
  my $deck_path = $self->deck_path;
  say STDERR "Looking at ls $deck_path/card*.png";
  my @card_paths = `ls $deck_path/card*.png`;
  @card_paths = map { chomp ; $_ } @card_paths;
  @card_paths = map { s/.*\/// ; $_ } @card_paths;
  say "Card files: " . p(@card_paths);
  my $id = 0;
  my $deck = [ map {
    App::WebDeck::Card->new(
      back_img => 'back.png',
      face_img => $_,
      id => $id++,
    )
  } @card_paths ];
  p $deck;
  $self->cards($deck);
}

method get_card_by_id($id) {
  my ($card) = grep { $_->id == $id } @{ $self->cards };
  return $card;
}

}

