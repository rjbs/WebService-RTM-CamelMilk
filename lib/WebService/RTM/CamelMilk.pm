use v5.24.0;
use warnings;

package WebService::RTM::CamelMilk;
use Moo;

use experimental qw(lexical_subs signatures);

use Digest::MD5 ();
use JSON::MaybeXS ();
use URI;
use URI::Escape qw(uri_escape_utf8);

my $AUTH_URI = 'https://api.rememberthemilk.com/services/auth/';
my $REST_URI = 'https://api.rememberthemilk.com/services/rest/';

my $JSON = JSON::MaybeXS->new;

has auth_uri => (is => 'ro', default => $AUTH_URI);
has rest_uri => (is => 'ro', default => $REST_URI);

has api_key    => (is => 'ro', required => 1);
has api_secret => (is => 'ro', required => 1);

has http_client => (is => 'ro', required => 1);

sub _signed_content ($self, $call) {
  my $str = $self->api_secret;
  my @hunks;

  my %call = (
    api_key => $self->api_key,
    %$call,
  );

  for (sort keys %call) {
    $str .= "$_$call{$_}";
    push @hunks, join q{=}, uri_escape_utf8($_), uri_escape_utf8($call{$_});
  }

  return join q{&}, @hunks, 'api_sig=' . Digest::MD5::md5_hex($str);
}

sub api_call ($self, $name, $arg = {}) {
  my $res_f = $self->http_client->do_request(
    uri    => $self->rest_uri,
    method => 'POST',
    content_type => 'application/x-www-form-urlencoded',
    content => $self->_signed_content({
      format  => 'json',
      %$arg,
      method  => $name,
    }),
  );

  return $res_f->then(sub ($res) {
    unless ($res->is_success) {
      return Future->fail(
        "HTTP request to RTM API failed",
        camel_milk => (response => $res),
      );
    }

    my $data = $JSON->decode($res->decoded_content);

    # {"rsp": {
    #     "stat":"ok",
    #     "auth":{
    #       "token":"...",
    #       "perms":"delete",
    #       "user":{"id":"123","username":"jfblogs","fullname":"J. Blogs"}
    #     } } }
    return Future->done(
      WebService::RTM::CamelMilk::APIResponse->from_payload($data)
    );
  });

  sub new_standalone ($self, $arg = {}) {
    require IO::Async::Loop;
    require Net::Async::HTTP;

    my $loop = IO::Async::Loop->new;
    my $http = Net::Async::HTTP->new;
    $loop->add($http);

    return WebService::RTM::CamelMilk::Standalone->new({
      %$arg,
      _loop => $loop,
      http_client => $http,
    });
  }
}

package WebService::RTM::CamelMilk::Standalone {

  use Moo;
  extends 'WebService::RTM::CamelMilk';

  has loop => (is => 'ro', required => 1, init_arg => '_loop');

  no Moo;
}

package WebService::RTM::CamelMilk::APIResponse {

  use Moo;

  use experimental qw(lexical_subs signatures);

  has _response => (is => 'ro', required => 1);
  has _weird_extra_data => (is => 'ro');

  sub from_payload ($class, $data) {
    my $response = delete $data->{rsp};
    $class->new({
      _response => $response,
      (keys %$data ? (_weird_extra_data => $data) : ()),
    });
  }

  sub get { $_[0]->_response->{$_[1]} }

  sub is_success { $_[0]->_response->{stat} eq 'ok' }

  no Moo;
}

no Moo;
1;
