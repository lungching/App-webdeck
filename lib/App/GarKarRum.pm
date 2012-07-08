package App::GarKarRum;

=head1 NAME

App::GarKarRum - Web based deck of cards

=cut

use v5.14;

use everywhere '5.010; use MooseX::Declare',
  matching => '^App/GarKarRum';

use Continuity;
use File::ShareDir;
use App::GarKarRum::Session;

sub make_app {

  my $share_dir = eval { File::ShareDir::dist_dir('App-GarKarRum') };
  $share_dir = 'share' if $@ || -d 'share'; # for development mode

  my $server = Continuity->new(
    query_session  => 'sid',
    cookie_session => 0,
    docroot        => $share_dir,
    callback       => sub {
      my $app = App::GarKarRum::Session->new(
        request => shift,
        docroot => $share_dir
      );
      $app->main();
    },
    debug_level => 2,
  );

  # This is how Continuity builds its $app
  return $server->loop;
}

1;

