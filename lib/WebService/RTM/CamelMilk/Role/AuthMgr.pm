use v5.24.0;
use warnings;

package WebService::RTM::CamelMilk::Role::AuthMgr;

use Moo::Role;

requires 'load_config';
requires 'save_config';

requires 'load_tokens';
requires 'save_tokens';

requires 'add_token';

no Moo::Role;
1;
