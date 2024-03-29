use v5.34.0;
use warnings;

package WebService::RTM::CamelMilk::Role::AuthMgr;
# ABSTRACT: something for storing CamelMilk config and tokens

use Moo::Role;

use feature qw(lexical_subs postderef_qq);
use experimental qw(signatures);

requires 'config';
requires 'load_config';
requires 'save_config';

requires 'tokens';
requires 'load_tokens';
requires 'save_tokens';

requires 'add_token';

sub auth_for_username ($self, $username) {
  my ($user, $more) = grep {; fc $_->{user}{username} eq fc $username }
                      values $self->tokens->%*;

  return unless $user;

  if ($more) {
    warn "two config entries for username <$username>";
    return;
  }

  return $user;
}

no Moo::Role;
1;
