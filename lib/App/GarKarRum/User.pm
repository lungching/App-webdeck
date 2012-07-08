
class App::GarKarRum::User {

=head1 NAME

App::GarKarRum::User - A user or player

=head1 DESCRIPTION

Dev-note: I think this should probably be split into user and player. A player would be someone actively at a table, whereas a user is more of an external entity. Right now we're really only dealing with players.

=cut

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

