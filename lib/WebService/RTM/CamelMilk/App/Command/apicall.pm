use v5.34.0;
use warnings;

package WebService::RTM::CamelMilk::App::Command::apicall;
# ABSTRACT: make an arbitrary API call

use WebService::RTM::CamelMilk::App -command;

use feature qw(lexical_subs postderef_qq);
use experimental qw(signatures);

sub abstract { 'make an arbitrary API call' }

sub usage_desc { '%c authuser %o METHOD [PARAM=VALUE]...' }

sub opt_spec {
  return (
    [ 'config|c=s', 'directory where config lives' ],
    [ 'username|u=s', 'username as whom to make the call' ],
    [ 'pretty!',      'prettify JSON; true by default', { default => 1 } ],
  );
}

sub execute ($self, $opt, $args) {
  my $config_dir = $self->get_existing_config_dir($opt);

  require WebService::RTM::CamelMilk::AuthMgr::Dir;

  my $authmgr = WebService::RTM::CamelMilk::AuthMgr::Dir->new({
    dir => $config_dir,
  });

  my ($method, @params) = @$args;

  unless ($method) {
    $self->usage->die({ pre_text => "No method name given!\n\n" })
  }

  my %param = map {;  m/=/ || die "params must be given in X=Y form\n";
                      split /=/, $_, 2 } @params;

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

  my $json = JSON::MaybeXS->new;

  if ($opt->pretty) {
    $json->canonical->pretty
  }

  print $json->encode($rsp->_response);
}

1;
