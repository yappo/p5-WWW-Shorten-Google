package WWW::Shorten::Google;
use strict;
use warnings;
use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );

our $VERSION = '0.02';

use Carp;
use JSON::PP;
use LWP::Protocol::https;

sub makeashorterlink {
    my $uri = shift or croak 'No URL passed to makeashorterlink';
    my $ua  = __PACKAGE__->ua();
    my $res = $ua->post(
        'https://www.googleapis.com/urlshortener/v1/url',
        'Content-Type' => 'application/json',
        'Content' => encode_json({longUrl => $uri}),
    );

    return unless $res->is_success;
    my $content = decode_json($res->content);
    if ($res->content =~ m!(\Qhttp://goo.gl/\E\w+)!x) {
        return $1;
    }
    return;
}

sub makealongerlink {
    my $uri = shift or croak 'No URL passed to makealongerlink';

    my $ua = __PACKAGE__->ua();

    $uri = "http://goo.gl/$uri" unless $uri =~ m!^http://!i;

    my $res = $ua->get(
        'https://www.googleapis.com/urlshortener/v1/url'
         . '?shortUrl=' . $uri
         . '&projection=FULL'
    );

    return unless $res->is_success;
    my $data = decode_json($res->content);
    return $data->{longUrl};
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::Shorten::Google -  Perl interface to goo.gl

=head1 SYNOPSIS

  use WWW::Shorten::Google;
  use WWW::Shorten 'Google';

  $short_url = makeashorterlink($long_url);
  $long_url  = makealongerlink($short_url);

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

sunnavy

=head1 SEE ALSO

L<WWW::Shorten>, L<http://goo.gl/>,
L<https://developers.google.com/url-shortener/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
