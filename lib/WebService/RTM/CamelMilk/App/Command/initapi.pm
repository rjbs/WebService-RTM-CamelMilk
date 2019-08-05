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
    [ 'dir|d=s',      'directory in which to write config',
      { default => $ENV{CAMEL_MILK_CONFIG} } ],
  );
}

sub execute ($self, $opt, $args) {
  die "target directory not provided\n" unless length $opt->dir;
  die "target directory already exists\n" if -e $opt->dir;
  die "error creating target directory: $!\n" unless mkdir $opt->dir;

  require WebService::RTM::CamelMilk::AuthMgr::Dir;

  my $authmgr = WebService::RTM::CamelMilk::AuthMgr::Dir->new({
    dir => $opt->dir,
  });

  $authmgr->config({
    api_secret => $opt->api_secret,
    api_key    => $opt->api_key,
  });

  $authmgr->save_config;

  return;
}

1;
