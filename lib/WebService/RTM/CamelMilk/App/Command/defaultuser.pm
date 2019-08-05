use v5.24.0;
use warnings;

package WebService::RTM::CamelMilk::App::Command::defaultuser;
use WebService::RTM::CamelMilk::App -command;

use experimental qw(lexical_subs signatures);

sub abstract { 'set the default API user' }

sub usage_desc { '%c defaultuser %o USERNAME' }

sub opt_spec {
  return (
    [ 'config|c=s', 'directory where config lives',
      { default => $ENV{CAMEL_MILK_CONFIG} } ],
  );
}

sub execute ($self, $opt, $args) {
  die "config directory not provided\n" unless length $opt->config;
  die "config directory does not exist or is not a directory\n"
    unless -d $opt->config;

  $self->usage->die unless @$args == 1;

  my $username = $args->[0];

  require WebService::RTM::CamelMilk::AuthMgr::Dir;

  my $authmgr = WebService::RTM::CamelMilk::AuthMgr::Dir->new({
    dir => $opt->config,
  });

  my $tokens = $authmgr->load_tokens;

  my ($user, $more) = grep {; fc $_->{user}{username} eq fc $username }
                      values %$tokens;

  die "no user with username $username\n" unless $user;
  die "woah, multiple users with that username!\n" if $more;

  $authmgr->config->{default_user} = $user->{user}{id};
  $authmgr->save_config;

  return;
}

1;