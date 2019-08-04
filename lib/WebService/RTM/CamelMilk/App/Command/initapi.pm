use strict;
use warnings;

package WebService::RTM::CamelMilk::App::Command::initapi;
use WebService::RTM::CamelMilk::App -command;

use experimental qw(lexical_subs signatures);

sub abstract { 'initialize config for an API registration' }

sub usage_desc { '%c initapi %o' }

sub opt_spec {
  return (
    [ 'api-secret=s', 'your API secret', { required => 1 } ],
    [ 'api-key=s',    'your API key',    { required => 1 } ],
    [ 'dir|d=s',      'directory in which to write config', { required => 1 } ],
  );
}

sub execute ($self, $opt, $args) {
  die "target directory already exists\n" if -e $opt->dir;
  die "error creating target directory: $!\n" unless mkdir $opt->dir;

  require JSON::MaybeXS;
  require Path::Tiny;

  my $fn = Path::Tiny::path($opt->dir)->child('api.json');
  open my $fh, '>', $fn or die "error opening $fn to write: $!\n";

  print {$fh} JSON::MaybeXS->new->canonical->pretty->encode({
    secret => $opt->api_secret,
    key    => $opt->api_key,
  });

  close $fh or die "error closing $fn after writing: $!\n";

  return;
}

1;
