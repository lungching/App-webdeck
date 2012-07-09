
class App::GarKarRum::Session {

=head1 NAME

App::GarKarRum::Session - A single player's connection to the server

=head1 DESCRIPTION

Each browser (client) gets two sessions. One session is for normal sends to the server, such as when they move a card. The second is a long-pull (push) session, which waits for updates from the server.

Dev note: Probably we should think about these two separate sessions and work out how they should be separated in the code layout, if they indeed need such treatment.

=cut

use App::GarKarRum::SimpleRoute;
use App::GarKarRum::Table;
use Template::Semantic;
use JSON::XS;
use List::MoreUtils qw/all/;
use Data::Printer;

our @movewatch_list = ();

# For now we'll just have one global table
# Later we'll have a list of them
our $global_table;

has docroot => (is => 'rw'); # Maybe this shouldn't be per-session
has request => (is => 'rw');

has table => (
  is  => 'rw',
  isa => 'Maybe[App::GarKarRum::Table]',
);

method initialize_table {
  say "Initializing table!";
  $global_table = App::GarKarRum::Table->new(
    deck_path => $self->docroot . "/img/classic-jokers",
  );
}

method index {

  # bah. this will change once we have a table list
  if(! $global_table) {
    $self->initialize_table;
  }
  $self->table($global_table);

  $self->request->print(
    Template::Semantic->process($self->docroot . "/template/hello.html" => {
      'title, #header h2'  => 'GarKarRum',
      '#thetable div.card' => [
        map { { 'img@src' => ("/img/classic-jokers/" . $_->back_img), 'img@id' => "card" . $_->id } }
        @{ $self->table->cards }
      ],
    })
  );
}

method stream {
  # Return the SessionID right away
  $self->request->print(encode_json({
    sid => $self->request->session_id,
  }));
  $self->request->next;

  # Now we'll stream them updates
  while(1) {
    my $watcher = AnyEvent->condvar;
    $global_table->add_cardmove_watcher( $watcher );
    my ($card, $action) = $watcher->recv; # wait for a move
    $self->request->print(encode_json({
      action => $action,
      card   => $card->to_hash,
      sid    => $self->request->session_id,
    }));
    $self->request->next;
  }
}

method move_card(:$id, :$x, :$y, :$z) {
  $id =~ s/^card//;
  print "move $id -> $x, $y, $z\n";

  $global_table->move_card(
    card_id => $id,
    x => $x,
    y => $y,
    z => $z,
  );

  # Output something so that the AJAX request won't get mad :)
  $self->request->print("Card moved!");
  # close session HERE
}

method flip_card(:$id) {
  $id =~ s/^card//;
  say "flip card $id";

  $global_table->flip_card( card_id => $id );

  $self->request->print("Card flipped!");

}


method main {
  my $path = $self->request->url_path;
  route $path => [
    '/hello'                 => sub { $self->request->print("HELLO") },
    '/stream'                => sub { $self->stream },
    '/movecard/:id/:x/:y/:z' => sub { $self->move_card(@_) },
    '/flipcard/:id'          => sub { $self->flip_card(@_) },
    '.*'                     => sub { $self->index },
  ];
}

}

