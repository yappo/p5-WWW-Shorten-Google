
use strict;
use warnings;
use Test::More;
require WWW::Shorten::Google;

is(WWW::Shorten::Google::_generate_auth_token('http://search.cpan.org/'), '721677627115');

done_testing;
