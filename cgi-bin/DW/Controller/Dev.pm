#!/usr/bin/perl
#
# DW::Controller::Dev
#
# This controller is for tiny pages related to dev work
#
# Authors:
#      Afuna <coder.dw@afunamatata.com>
#
# Copyright (c) 2010-2011 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.
#

package DW::Controller::Dev;

use strict;
use warnings;
use DW::Routing;

DW::Routing->register_static( '/dev/classes', 'dev/classes.tt', app => 1 );

if ( $LJ::IS_DEV_SERVER ) {
    DW::Routing->register_string( '/dev/tests/index', \&tests_index_handler, app => 1 );
    DW::Routing->register_regex( '/dev/tests/([^/]+)(?:/(.*))?', \&tests_handler, app => 1 )
}

sub tests_index_handler {
    my ( $opts ) = @_;

    my $r = DW::Request->get;

    $r->note( bml_use_scheme => "global" );
    return DW::Template->render_template( "dev/tests-all.tt", {
        all_tests => [ map { $_ =~ m!tests/([^/]+)\.js!; } glob("$LJ::HOME/views/dev/tests/*.js") ]
    } );
}
    
sub tests_handler {
    my ( $opts ) = @_;
    my $test = $opts->subpatterns->[0];
    my $lib = $opts->subpatterns->[1];

    my $r = DW::Request->get;

    if ( ! defined $lib ) {
        return $r->redirect("$LJ::SITEROOT/dev/tests/$test/");
    } elsif ( ! $lib ) {
        $r->note( bml_use_scheme => "global" );
        return DW::Template->render_template( "dev/tests-all.tt", {
            test => $test,
        } );
    }

    my @includes;
    my $testcontent = eval{ DW::Template->template_string( "dev/tests/${test}.js" ) } || "";
    if ( $testcontent ) {
        $testcontent =~ m#/\*\s*INCLUDE:\s*(.*?)\*/#s;
        my $match = $1;
        for my $res ( split( /\n+/, $match ) ) {

            # skip things that don't look like names (could just be an empty line)
            next unless $res =~ /\w+/;

            # remove the library label
            $res =~ s/(\w+)://;

            # skip if we specify a library that's different from our current library
            next if $1 && $1 ne $lib;

            push @includes, LJ::trim( $res );
        }
    }

    my $testhtml = eval{ DW::Template->template_string( "dev/tests/${test}.html" ) }
            || "<!-- no html template -->";

    # force a site scheme which only shows the bare content
    # but still prints out resources included using need_res
    $r->note( bml_use_scheme => "global" );

    # we don't validate the test name, so be careful!
    return DW::Template->render_template( "dev/tests.tt", {
            testname => $test,
            testlib  => $lib,
            testhtml => $testhtml,
            tests    => $testcontent,
            includes => \@includes,
         } );
}
1;
