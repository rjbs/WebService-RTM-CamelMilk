use v5.34.0;
use warnings;

package WebService::RTM::CamelMilk::App::Command::defaultuser;
# ABSTRACT: set the default API user

use WebService::RTM::CamelMilk::App -command;

use feature qw(lexical_subs postderef_qq);
use experimental qw(signatures);

sub abstract { 'set the default API user' }

sub usage_desc { '%c defaultuser %o USERNAME' }

sub opt_spec {
  return (
    [ 'config|c=s', 'directory where config lives' ],
  );
}

sub execute ($self, $opt, $args) {
  my $config_dir = $self->get_existing_config_dir($opt);

  $self->usage->die unless @$args == 1;

  my $username = $args->[0];

  require WebService::RTM::CamelMilk::AuthMgr::Dir;

  my $authmgr = WebService::RTM::CamelMilk::AuthMgr::Dir->new({
    dir => $config_dir,
  });

  my $user = $authmgr->auth_for_username($username);
  die "Can't resolve $username to a stored token\n" unless $user;

  $authmgr->config->{default_user} = $user->{user}{id};
  $authmgr->save_config;

  return;
}

1;
