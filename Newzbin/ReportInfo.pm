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

# Implements the reportinfo api on newzbin

package Newzbin::ReportInfo;

use strict;
use warnings;

use LWP::UserAgent;
use XML::Parser;
use Carp;

sub new {
    my $package = shift;
    my $options = shift;
    return bless $options, $package;
}

sub info {
    my ( $self, $id ) = @_;
    my $post_params = {};
    $post_params->{username} = $self->{username};
    $post_params->{password} = $self->{password};
    $post_params->{id}       = $id;
    my $ua = LWP::UserAgent->new;
    my $res =
      $ua->post( "http://www.newzbin.com/api/reportinfo/", $post_params );

    if ( $res->code == 503 ) {
        cluck("503 Service Unavailable (Newzbin is down for maintenance/etc)");
        return undef;
    }
    elsif ( $res->code == 500 ) {
        cluck("500 Internal Server Error (Newzbin broke)");
        return undef;
    }
    elsif ( $res->code == 404 ) {
        cluck("404 Report Not Found");
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
        my $p1 = new XML::Parser( Style => 'Tree' );
        my $xml = $res->content;
        my $tree = $p1->parse($xml)->[1];

        # Make the data more useful for perl scripts. This needs work.
        my $ref = _maketree($tree);

        my @attributes;
        for ( my $i = 0 ; $i < @{ $ref->{attributes} } ; $i++ ) {
            if ( $ref->{attributes}->[$i] eq 'attribute' ) {
                my $type = $ref->{attributes}[ ++$i ][0]->{type};
                for ( my $x = 0 ; $x < @{ $ref->{attributes}[$i] } ; $x++ ) {
                    if ( $ref->{attributes}[$i][$x] eq 'value' ) {
                        push @attributes,
                          { $type => $ref->{attributes}[$i][ ++$x ][2] };
                    }
                }
            }
        }
        $ref->{attributes} = \@attributes;

        my @files;
        for ( my $i = 0 ; $i < @{ $ref->{files} } ; $i++ ) {
            if ( $ref->{files}->[$i] eq 'file' ) {
                push @files, $ref->{files}[ ++$i ][0];
            }
        }
        $ref->{files} = \@files;

        my @tags;
        for ( my $i = 0 ; $i < @{ $ref->{tags} } ; $i++ ) {
            if ( $ref->{tags}->[$i] eq 'tag' ) {
                push @tags, $ref->{tags}[ ++$i ][0]{title};
            }
        }
        $ref->{tags} = \@tags;

        my @flags;
        for ( my $i = 0 ; $i < @{ $ref->{flags} } ; $i++ ) {
            if ( $ref->{flags}->[$i] eq 'flag' ) {
                push @flags, $ref->{flags}[ ++$i ][0];
            }
        }
        $ref->{flags} = \@flags;

        my @ng;
        for ( my $i = 0 ; $i < @{ $ref->{newsgroups} } ; $i++ ) {
            if ( $ref->{newsgroups}->[$i] eq 'newsgroup' ) {
                push @ng, $ref->{newsgroups}[ ++$i ][2];
            }
        }
        $ref->{newsgroups} = \@ng;

        $ref->{progress} = $ref->{progress}[2];
        $ref->{status}   = $ref->{status}[2];
        $ref->{category} = $ref->{category}[2];
        $ref->{size}     = $ref->{size}[2];
        $ref->{id}       = $ref->{id}[2];
        $ref->{url}      = $ref->{url}[2];
        $ref->{title}    = $ref->{title}[2];
        $ref->{poster}   = $ref->{poster}[2];
        return $ref;
    }
    return undef;
}

sub _flatten_tree {
    my ( $tree, $tag ) = @_;

}

sub _maketree {
    my ($tree) = @_;
    return {} if not ref $tree eq 'ARRAY';
    my $ref = {};
    for ( my $i = 0 ; $i < scalar @$tree ; $i++ ) {
        if ( $tree->[$i] =~ m/([a-z]+)/ ) {
            $ref->{$1} = $tree->[ ++$i ];
        }
    }
    return $ref;
}
1;
