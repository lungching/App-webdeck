
class App::WebDeck::Session {

=head1 NAME

App::WebDeck::Session - A single player's connection to the server

=head1 DESCRIPTION

Each browser (client) gets two sessions. One session is for normal sends to the server, such as when they move a card. The second is a long-pull (push) session, which waits for updates from the server.

Dev note: Probably we should think about these two separate sessions and work out how they should be separated in the code layout, if they indeed need such treatment.

=cut

use App::WebDeck::SimpleRoute;
use App::WebDeck::Table;
use Template::Semantic;
use JSON::XS;
use List::MoreUtils qw/all/;
use Data::Dumper;

our @movewatch_list = ();
our $deck = [];

# For now we'll just have one global table
# Later we'll have a list of them
our $global_table;

has docroot => (is => 'rw'); # Maybe this shouldn't be per-session
has request => (is => 'rw');

has table => (
  is  => 'rw',
  isa => 'Maybe[App::WebDeck::Table]',
);

method initialize_table {
  say "Initializing table!";
  $global_table = App::WebDeck::Table->new(
    deck_path => $self->docroot . "/img/classic-jokers",
  );
  use Data::Printer;
  p($global_table);
}

method index {

  # bah. this will change once we have a table list
  if(! $global_table) {
    $self->initialize_table;
  }
  $self->table($global_table);

  $self->request->print(
    Template::Semantic->process($self->docroot . "/template/hello.html" => {
      'title, #header h2'  => 'WebDeck',
      '#thetable h2'       => $self->request->session_id,
      '#thetable div.card' => [
        map { { 'img@src' => ("/img/classic-jokers/" . $_->face_img), 'img@id' => "card" . $_->id } }
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
    push @movewatch_list, $watcher;
    my ($card) = $watcher->recv; # wait for a move
    $self->request->print(encode_json({
      action => 'movecard',
      card   => $card->to_hash,
      sid    => $self->request->session_id,
    }));
    $self->request->next;
  }
}

method movecard(:$id, :$x, :$y, :$z) {
  print "move $id -> $x, $y, $z\n";
  $id =~ s/card//;

  # my $card = $self->table->get_card_by_id($id);
  my $card = $global_table->get_card_by_id($id);

  # Set our new position
  $card->position([$x, $y, $z]);

  # Notify all listeners that we have done a move
  while(my $watcher = shift @movewatch_list) {
    $watcher->send($card);
  }

  # Output something so that the AJAX request won't get mad :)
  $self->request->print("Card moved!");
  # close session HERE
}

method main {
  my $path = $self->request->url_path;
  route $path => [
    '/hello'                 => sub { $self->request->print("HELLO") },
    '/stream'                => sub { $self->stream },
    '/movecard/:id/:x/:y/:z' => sub { $self->movecard(@_) },
    '.*'                     => sub { $self->index },
  ];
}

}

