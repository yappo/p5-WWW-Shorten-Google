package WWW::Shorten::Google;
use strict;
use warnings;
use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );

our $VERSION = '0.01';

use Carp;
use POSIX 'floor';
use JSON::Any;

sub _c {
    my $l = 0;
    for my $val (@_) {
        $val &= 4294967295;
        # 32bit signed
        $val += $val > 2147483647 ? -4294967296 :
                    $val < -2147483647 ? 4294967296 : 0;
        $l += $val;
        # 32bit signed
        $l += $l > 2147483647 ? -4294967296 :
                  $l < -2147483647 ? 4294967296 : 0;
    }
    return $l;
}

sub _e {
    my $uri = shift;

    my $m   = 5381;
    for my $char (split '', $uri) {
        $m = _c( $m << 5, $m, unpack('C', $char) );
    }
    return $m;
}

sub _f {
    my $uri = shift;

    my $m   = 0;
    for my $char (split '', $uri) {
        $m = _c( unpack('C', $char), $m << 6, $m << 16, -$m );
    }
    return $m;
}

sub _d {
    my $l = shift;
    $l = ( $l > 0 ) ? $l : $l + 4294967296;

    my $m = "$l";
    my $n = 0;
    my $o = 0;
    for my $char (reverse split '', $m) {
        my $q = $char + 0;
        $o += $n ? ($q *= 2, floor($q / 10) + $q % 10) : $q;
        $n = !$n;
    }

    $m = $o % 10;
    $o = 0;

    if ($m != 0) {
        $o = 10 - $m;
        if (length($l) % 2 == 1) {
            $o += 9 if $o % 2 == 1;
            $o /= 2;
        }
    }

    return "$o$l";
}


sub _generate_auth_token {
    my $uri = shift;

    my $i = _e($uri);
    $i = $i >> 2 & 1073741823;
    $i = $i >> 4 &   67108800 | $i &    63;
    $i = $i >> 4 &    4193280 | $i &  1023;
    $i = $i >> 4 &     245760 | $i & 16383;

    my $h = _f($uri);

    my $k = ($i >>  2 & 15) <<  4 | $h & 15;
    $k   |= ($i >>  6 & 15) << 12 | ($h >>  8 & 15) <<  8;
    $k   |= ($i >> 10 & 15) << 20 | ($h >> 16 & 15) << 16;
    $k   |= ($i >> 14 & 15) << 28 | ($h >> 24 & 15) << 24;
    my $j = "7" . _d($k);
}

sub makeashorterlink {
    my $uri = shift or croak 'No URL passed to makeashorterlink';
    my $user = shift || 'toolbar@google.com';

    my $token = _generate_auth_token $uri;

    my $ua = __PACKAGE__->ua();
    my $res = $ua->post(
        'http://goo.gl/api/url' => [
            user       => $user,
            url        => $uri,
            auth_token => $token,
        ]
    );
    return unless $res->is_success;

    my $json = JSON::Any->jsonToObj( $res->content );
    return unless $json->{short_url};
    return $json->{short_url};
}

sub makealongerlink {
    my $uri = shift or croak 'No URL passed to makealongerlink';

    my $ua = __PACKAGE__->ua();

    $uri = "http://goo.gl/$uri" unless $uri =~ m!^http://!i;

    my $res = $ua->get($uri);
    return unless $res->is_redirect;
    return $res->header('Location');
}



1;
__END__

=head1 NAME

WWW::Shorten::Google -  Perl interface to goo.gl

=head1 SYNOPSIS

  use WWW::Shorten::Google;
  use WWW::Shorten 'Google';

  $short_url = makeashorterlink($long_url);
  $long_url  = makealongerlink($short_url);

  $short_url = makeashorterlink($long_url, 'YOUR goo.gl USER NAME');

=head1 DESCRIPTION

WWW::Shorten::Google is Perl interface to the web api goo.gl.

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the Google URL Shortener web site passing
it your long URL and will return the shorter Google URL Shortener version.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full Google URL Shortener URL or just the Google URL Shortener identifier.

If anything goes wrong, then either function will return C<undef>.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

L<WWW::Shorten>, L<http://goo.gl/>, my idea takes by L<http://www.kix.in/blog/2009/12/goo-gl/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
