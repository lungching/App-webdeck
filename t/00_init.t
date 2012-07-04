#!/usr/bin/env perl

use strict;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Runner; # Force Continuity
 
$Plack::Test::Impl = 'AnyEvent'; # or 'AE' for short

use App::WebDeck;

my $app = App::WebDeck::make_app();
 
test_psgi $app, sub {
  my $cb = shift;
  use Data::Printer;
  my $res = $cb->(GET '/');
  $res->on_content_received( sub {
    my $content = shift;
    like $content, qr/card-\d\d.png/, 'Found card';
  });
  $res->recv;
};

done_testing();

