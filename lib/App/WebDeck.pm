
class App::WebDeck {

=head1 NAME

App::WebDeck - A Web-Based Deck of Cards Server

=cut

use SimpleRoute;
use Continuity;
use Template::Semantic;
use Coro::AnyEvent;
use JSON::XS;
use List::MoreUtils qw/all/;
use Data::Dumper;

our $movewatch = AnyEvent->condvar;
our @movewatch_list = ();
our $deck = [];

has request => (is => 'rw');

# has deck => (is => 'rw', default => sub { [] });
# has movewatch => (is => 'rw', default => sub { AnyEvent->condvar });

method initialize_deck {
  my @card_paths = `ls img/classic-jokers/card*.png`;
  @card_paths = map { chomp ; $_ } @card_paths;
  my $id = 0;
  $deck = [ map { {
    path => "/$_",
    x => 0,
    y => 0,
    z => 0,
    id => $id++,
  } } @card_paths ];
}

method index {
  if(! @{ $deck }) {
    $self->initialize_deck;
  }
  $self->request->print(
    Template::Semantic->process('template/hello.html' => {
      'title, #header h2' => 'WebDeck',
      '#thetable h2' => $self->request->session_id,
      '#thetable div.card' => [
        map { { 'img@src' => $_->{path}, 'img@id' => "card$_->{id}" } } @{ $deck }
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
    say "Waiting for movewatch";
    say "Current movewatch: " . $watcher;
    my ($id) = $watcher->recv; # wait for a move
    say "GOT movewatch! id: $id";
    say Dumper($deck->[$id]);
    $self->request->print(encode_json({
      action => "movecard",
      id => "card$id",
      x => $deck->[$id]->{x},
      y => $deck->[$id]->{y},
      z => $deck->[$id]->{z},
      sid => $self->request->session_id,
    }));
    $self->request->next;
  }
}

method movecard($id, $x, $y, $z) {
  print "move $id -> $x, $y, $z\n";
  $id =~ s/card//;
  $deck->[$id]->{x} = $x;
  $deck->[$id]->{y} = $y;
  $deck->[$id]->{z} = $z;

  say "Current movewatch: " . $movewatch;
  say "Sending movewatch $id";
  while(my $watcher = shift @movewatch_list) {
    $watcher->send($id);
  }

  $self->request->print("Card moved!");
}

method main {
  my $path = $self->request->url_path;
    say "main - Current movewatch: " . $movewatch;
  route $path => [
    '/hello'  => sub { $self->request->print("HELLO") },
    '/stream' => sub { $self->stream },
    '/movecard/:id/:x/:y/:z' => sub {
      my %params = @_;
      $self->movecard($params{id}, $params{x}, $params{y}, $params{z});
    },
    '.*'      => sub { $self->index },
  ];
}

}
