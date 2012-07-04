
class App::WebDeck::User {

has username => (
  is  => 'rw',
  isa => 'Str',
);

# x,y coordinate of drop-point
has position => (
  is      => 'rw',
  isa     => 'ArrayRef[Int]',
  default => sub { [0,0] },
);

}

