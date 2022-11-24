use v5.34.0;
use warnings;

package WebService::RTM::CamelMilk::App::Command::authuser;
# ABSTRACT: set up an authentication for an RTM user

use WebService::RTM::CamelMilk::App -command;

use feature qw(lexical_subs postderef_qq);
use experimental qw(signatures);

sub abstract { 'set up an authentication for an RTM user' }

sub usage_desc { '%c authuser %o' }

sub opt_spec {
  return (
    [ 'config|c=s', 'directory where config lives' ],
    [ 'permissions|p=s', 'permissions to request: read, write, or delete',
      { default => 'delete' } ],
  );
}

sub execute ($self, $opt, $args) {
  my $config_dir = $self->get_existing_config_dir($opt);

  require WebService::RTM::CamelMilk::AuthMgr::Dir;

  my $authmgr = WebService::RTM::CamelMilk::AuthMgr::Dir->new({
    dir => $config_dir,
  });

  require WebService::RTM::CamelMilk;
  my $milk = WebService::RTM::CamelMilk->new_standalone({
    api_key     => $authmgr->config->{api_key},
    api_secret  => $authmgr->config->{api_secret},
  });

  my $frob_rsp = $milk->api_call('rtm.auth.getFrob' => {})->get;

  unless ($frob_rsp->is_success) {
    die "Something went wrong initializing our authentication request.\n"
  }

  my $frob = $frob_rsp->get('frob');

  my $auth_uri = join q{?},
    "https://www.rememberthemilk.com/services/auth/",
    $milk->_signed_content({ frob => $frob, perms => $opt->permissions });

  printf <<EOT, $auth_uri;
Okay, we started the authentication process by getting a request id from
Remember The Milk.  They call this a frob.  Why?  Why not!  We'll use this to
get an authentication token, but first you have to go tell Remember The Milk
that you want to authorize the holder of this frob to do stuff.  Open the link
below and approve access.

When you've followed the link and authorized cmilk, press enter.

%s
EOT

  scalar <STDIN>;

  my $token_rsp = $milk->api_call('rtm.auth.getToken' => { frob => $frob })
                       ->get;

  die "Remember The Milk rejected our request to get a token!\n"
    unless $token_rsp->is_success;

  # The auth component is:
  #   perms: {delete, write, read}
  #   token: $long-hex-string
  #   user : {
  #     id: $integer
  #     fullname: Jane Doe
  #     username: jdoe
  #   }

  my $auth = $token_rsp->get('auth');
  printf "Token for user %s acquired: %s\n",
    $auth->{user}{username}, $auth->{token};

  my $result = $authmgr->add_token($auth);
  printf "token $result\n";

  $authmgr->save_tokens;

  print "token file updated!\n";

  return;
}

1;
