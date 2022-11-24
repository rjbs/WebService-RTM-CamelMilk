use v5.34.0;
use warnings;

package WebService::RTM::CamelMilk::App::Command;
use App::Cmd::Setup -command;

use feature qw(lexical_subs postderef_qq);
use experimental qw(signatures);

sub get_config_dir ($self, $opt) {
  my $config_dir = ($opt->can('config') ? $opt->config : undef)
                // $ENV{CAMEL_MILK_CONFIG}
                // "$ENV{HOME}/.cmilk";

  unless (length $config_dir) {
    die "nonsensical empty config path given!\n";
  }

  return $config_dir;
}

sub get_existing_config_dir ($self, $opt) {
  my $config_dir = $self->get_config_dir($opt);

  unless (-d $config_dir) {
    die <<~"END"
    The expected configuration directory $config_dir does not exist.
    You may need to run "cmilk init" to set things up, or supply --config.
    END
  }

  return $config_dir;
}

1;
