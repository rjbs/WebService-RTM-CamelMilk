use v5.20.0;
use warnings;

package WebService::RTM::CamelMilk::AuthMgr::Dir;
# ABSTRACT: an auth manager that stores things in a directory on disk

use Moo;

use experimental qw(lexical_subs postderef signatures);

use JSON::MaybeXS ();
use Path::Tiny;

my $JSON = JSON::MaybeXS->new->canonical;

has dir => (
  is => 'ro',
  isa => sub {
    die "given directory is not a Path::Tiny"
      unless $_[0] && ref $_[0] && (ref $_[0])->isa('Path::Tiny')
  },
  coerce => sub { path($_[0]) },
  required => 1,
);

has config => (
  is   => 'rw',
  lazy => 1,
  builder => 'load_config',
);

sub load_config ($self) {
  $JSON->decode($self->dir->child('config.json')->slurp);
}

sub save_config ($self) {
  $self->dir->child('config.json')->spew( $JSON->encode($self->config) );
}

has tokens => (
  is   => 'rw',
  lazy => 1,
  builder => 'load_tokens',
);

sub load_tokens ($self) {
  my $file = $self->dir->child('tokens.json');
  return {} unless -e $file;
  $JSON->decode($file->slurp);
}

sub save_tokens ($self) {
  $self->dir->child('tokens.json')->spew( $JSON->encode($self->tokens) );
}

sub add_token ($self, $auth) {
  my $tokens = $self->tokens;

  my $status = 'added';

  if (my $existing = $tokens->{ $auth->{user}{id} }) {
    my $old = $JSON->encode($existing);
    my $new = $JSON->encode($auth);

    if ($old eq $new) {
      return 'present';
    }

    $status = 'replaced';
  }

  $tokens->{ $auth->{user}{id} } = $auth;
  return $status;
}

with 'WebService::RTM::CamelMilk::Role::AuthMgr';

1;
