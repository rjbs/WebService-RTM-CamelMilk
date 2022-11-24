use v5.34.0;
use warnings;

package WebService::RTM::CamelMilk::App::Command::initapi;
# ABSTRACT: initialize config for an API registration

use WebService::RTM::CamelMilk::App -command;

use feature qw(lexical_subs postderef_qq);
use experimental qw(signatures);

sub abstract { 'initialize config for an API registration' }

sub usage_desc { '%c initapi %o' }

sub opt_spec {
  return (
    [ 'api-secret=s', 'your API secret', { required => 1 } ],
    [ 'api-key=s',    'your API key',    { required => 1 } ],
    [ 'config|c=s',   'directory in which to write config' ],
  );
}

sub execute ($self, $opt, $args) {
  my $config_dir = $self->get_config_dir($opt);

  die "target directory not provided\n" unless length $config_dir;
  die "target directory already exists\n" if -e $config_dir;
  die "error creating target directory: $!\n" unless mkdir $config_dir;

  require WebService::RTM::CamelMilk::AuthMgr::Dir;

  my $authmgr = WebService::RTM::CamelMilk::AuthMgr::Dir->new({
    dir => $config_dir,
  });

  $authmgr->config({
    api_secret => $opt->api_secret,
    api_key    => $opt->api_key,
  });

  $authmgr->save_config;

  return;
}

1;
