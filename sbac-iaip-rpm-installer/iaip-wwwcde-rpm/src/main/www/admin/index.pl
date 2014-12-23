#!/usr/bin/perl -w
use strict;
use Admin;
use CGI;

my $cgi = CGI->new;
$cgi->param(-name => 'action', -values => 'displayMainPage') unless $cgi->param('action');

print $cgi->header( -type => 'text/html' );

my $admin = new Admin( cgi => $cgi );
$admin->run();

exit;
