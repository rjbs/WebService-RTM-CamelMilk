use strict;
use warnings;

package WebService::RTM::CamelMilk::App::Command::apicall;
# ABSTRACT: make an arbitrary API call


use WebService::RTM::CamelMilk::App -command;

use experimental qw(lexical_subs signatures);

sub abstract { 'set up an authentication for an RTM user' }

sub usage_desc { '%c authuser %o METHOD [PARAM=VALUE]...' }

sub opt_spec {
  return (
    [ 'config|c=s', 'directory where config lives',
      { default => $ENV{CAMEL_MILK_CONFIG} } ],
    [ 'username|u=s', 'username as whom to make the call' ],
  );
}

sub execute ($self, $opt, $args) {
  die "config directory not provided\n" unless length $opt->config;
  die "config directory does not exist or is not a directory\n"
    unless -d $opt->config;

  require WebService::RTM::CamelMilk::AuthMgr::Dir;

  my $authmgr = WebService::RTM::CamelMilk::AuthMgr::Dir->new({
    dir => $opt->config,
  });

  my ($method, @params) = @$args;

  $self->usage->die("no method name given") unless $method;
  my %param = map {;  m/=/ || die "params must be given in X=Y form\n";
                      split /=/ } @params;

  my $auth;
  if (my $username = $opt->username) {
    $auth = $authmgr->auth_for_username($username);
    die "can't get token for username $username\n" unless $auth;
  } elsif (my $default = $authmgr->config->{default_user}) {
    $auth = $authmgr->tokens->{ $default };
    die "default token no longer exists\n" unless $auth;
  } else {
    die "no username given and no default user\n";
  }

  $param{auth_token} = $auth->{token};

  require WebService::RTM::CamelMilk;
  my $milk = WebService::RTM::CamelMilk->new_standalone({
    api_key     => $authmgr->config->{api_key},
    api_secret  => $authmgr->config->{api_secret},
  });

  $method = "rtm.$method" unless $method =~ /\Artm\./;

  my $rsp = $milk->api_call($method=> \%param)->get;

  print JSON::MaybeXS->new->encode($rsp->_response);
}

1;
