# Copyright (c) 2009, Thomas Jager <mail@jager.no>

# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.

# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# Implements the reportfind api on newzbin

package Newzbin::ReportFind;

use strict;
use warnings;

use LWP::UserAgent;

sub new {
    my $package = shift;
    my $options = shift;
    return bless $options, $package;
}

sub find {
    my ( $self, $query, $options ) = @_;
    my $post_params = $options;
    $post_params->{username} = $self->{username};
    $post_params->{password} = $self->{password};
    $post_params->{query}    = $query;
    my $ua = LWP::UserAgent->new;
    my $res =
      $ua->post( "http://www.newzbin.com/api/reportfind/", $post_params );

    if ( $res->code == 503 ) {
        cluck("503 Service Unavailable (Newzbin is down for maintenance/etc)");
        return undef;
    }
    elsif ( $res->code == 500 ) {
        cluck("500 Internal Server Error (Newzbin broke)");
        return undef;
    }
    elsif ( $res->code == 402 ) {
        cluck("402 Payment Required (the account is not a premium account)");
        return undef;
    }
    elsif ( $res->code == 401 ) {
        cluck("401 Unauthorised incorrect authentication details");
        return undef;
    }
    elsif ( $res->code == 204 ) {
        return [];
    }
    elsif ( $res->code == 200 ) {
        my @results;
        my $data = $res->content;
        my ($count) = $data =~ s/TOTAL=(\d+)\n//xmsi;
        while ( $data =~ s/(\d+)\t(\d+)\t([^\n]+)\n//xmsi ) {
            push @results, { id => $1, size => $2, title => $3 };
        }
        return \@results;
    }
    return undef;
}
1;
