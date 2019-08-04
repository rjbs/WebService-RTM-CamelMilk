use strict;
use warnings;

package WebService::RTM::CamelMilk::App::Command::authuser;
use WebService::RTM::CamelMilk::App -command;

use experimental qw(lexical_subs signatures);

sub abstract { 'setup an authentication for an RTM user' }

sub usage_desc { '%c authuser %o' }

sub opt_spec {
  return (
    [ 'config|c=s', 'directory where config lives',
      { default => $ENV{CAMEL_MILK_CONFIG} } ],
    [ 'permissions|p=s', 'permissions to request: read, write, or delete',
      { default => 'delete' } ],
    [],
    [ 'debug', 'print full response when something goes wrong' ],
  );
}

sub execute ($self, $opt, $args) {
  die "config directory not provided\n" unless $opt->config;
  die "config directory does not exist or is not a directory\n"
    unless -d $opt->config;

  require JSON::MaybeXS;
  require Path::Tiny;

  my $dir = Path::Tiny::path($opt->config);
  my $fn  = $dir->child('api.json');

  die "config directory does not contain an api.json file\n"
    unless -e $fn;

  my $JSON = JSON::MaybeXS->new->canonical;

  open my $api_fh, '<', $fn or die "error opening $fn to read: $!\n";
  my $api_config = $JSON->decode(scalar do { local $/; <$api_fh> });

  require WebService::RTM::CamelMilk;
  my $milk = WebService::RTM::CamelMilk->new_standalone({
    api_key     => $api_config->{key},
    api_secret  => $api_config->{secret},
  });

  my $frob_rsp = $milk->api_call('rtm.auth.getFrob' => {})->get;

  unless ($frob_rsp->is_success) {
    print $JSON->encode({ %$frob_rsp }) if $opt->debug;
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

  my $tokenring = {}; # I know that's not what a token ring is.
  my $token_fn = $dir->child('tokens.json');

  if (-e $token_fn) {
    open my $token_fh, '<', $token_fn
      or die "error opening $token_fn to read: $!\n";
    $tokenring = $JSON->decode(scalar do { local $/; <$token_fh> });
  }

  if (my $existing = $tokenring->{ $auth->{user}{id} }) {
    my $old = $JSON->encode($existing);
    my $new = $JSON->encode($auth);

    if ($old eq $new) {
      print "authentication already on file\n";
      exit;
    }

    warn "replacing existing token for user\n";
  }

  $tokenring->{ $auth->{user}{id} } = $auth;

  $token_fn->spew( $JSON->encode( $tokenring ) );

  print "token file updated!\n";

  return;
}

1;
