#!/usr/bin/perl -I./modules
#-----------------------------------------------------------------------
#
# (c) Copyright SXOOP Technology 2005
#
# All rights reserved.
#
# This script (with the aid of supporting modules)
# performs all of the image transformations
#
#-----------------------------------------------------------------------
use strict;
BEGIN {
	 #
	 # Customers have reported problems with IIS6 where
	 # the current working directory is not the same as the directory
	 # in which the script resides.
	 # the following code ensures that the current working directory matches
	 # the directory in which the script resides.
	 # 
	 my ($rwd) = $0 =~ /(.+[\/\\])/;
	 #
	 # On some machines (perl 5.8.6 ?) $0 will be the script filename 
	 # with no path prefix.
	 #
	 if ($rwd eq ""){
		  $rwd = "./";
	 }
	 chdir $rwd;
	 #
	 # also required for IIS6 - IIS doesn't handle STDERR very well.
	 # the following will fix STDERR on IIS6
	 use CGI::Carp qw(fatalsToBrowser);
}

use CGI ':standard';
use Image::Magick;
use File::Copy;
use PXN8 ':all';
use Cwd;
use PXN8Debug;
use TinyTemplate ':all';

#
# load all plugins
#
my $pluginsDirectory = "./modules/plugins";
push @INC, $pluginsDirectory;

foreach (glob ("$pluginsDirectory/*.pm")){
	 require $_;
}

# ------------------------------------
# read and evaluate configuration file
# ------------------------------------
open CONFIG, "<config.ini" 
	 or die "Could not open configuration file config.ini $!\n";

no strict 'vars';
my $CONFIG = eval (join '',<CONFIG>);
use strict 'vars';

close CONFIG;

if (exists $CONFIG->{DEBUG}){
	 $PXN8Debug::debug = $CONFIG->{DEBUG};
}
if (exists $CONFIG->{LOG_DIR}){
	 $PXN8Debug::logdir = $CONFIG->{LOG_DIR};
}

# ------------------------------------------
# remove old files from the cache
# delete cache files older than $cacheAge
# ------------------------------------------

my @allCacheFiles = glob ("$CONFIG->{CACHE_DIR}/*");
my @jpegCacheFiles = grep /\.jpg$/i, @allCacheFiles;
my %cache = map { $_ => (stat $_)[9]} @jpegCacheFiles;

my @oldimages = ();
my $time = time();
foreach (keys %cache){
    if ($time - $cache{$_} > $CONFIG->{DELETE_TEMPS_AFTER}){ 
		  unlink $_; 
		  push @oldimages, $_;
	 }
}
PXN8Debug::log("removed the following files: @oldimages \n" );

# ----------------------------------------
# turn the script parameter into an array
# ----------------------------------------
my $query = new CGI();

my $script = $query->param('script');

my @script = grep /.+/, split /[\n\r]/, $script;

PXN8Debug::log ("pxn8.pl ---------------------------------\n");

foreach (0..$#script) {
	 PXN8Debug::log("$_ : $script[$_]\n");
}
PXN8Debug::log ("pxn8.pl ---------------------------------\n");

if (@script) {
	 # ------------------------------------------
	 # process the script, return the new Image
	 # ------------------------------------------
	 my ($imagefile, $uncompressed, $width, $height) = PXN8::imageFromScript(config => $CONFIG,
																									 script => [@script]);
	 $width = $width || -1;
	 $height = $height || -1;
	 print $query->header( -type => "text/plain", -expires => "-1d" );
	 
	 my $opNumber = scalar @script;
	 eval TinyTemplate::parse<<'JSON';
	 { "status"      : "OK",
		"image"       : "$imagefile",
		"uncompressed": "$uncompressed",
		"width"       : $width,
		"height"      : $height,
		"opNumber"    : $opNumber
	 }
JSON

}else{
	 print $query->header( -type => "text/plain", -expires => "-1d" );

	 my $im = new Image::Magick;
	 my $im_version = $im->Get("version");
	 my @im_formats = $im->QueryFormat();
	 my @im_fonts = $im->QueryFont();

	 eval TinyTemplate::parse<<'JSON';
	 { "status"      : "ERROR",
		"errorCode"   : 3500,
		"errorMessage": "No script supplied",
		"debug"       : { "imagemagick_version": "$im_version",
								// [% print $#im_formats+1; %] formats supported
								"imagemagick_formats": [ [% foreach (0..$#im_formats) { %]"$im_formats[$_]"[% if ($_ != $#im_formats){ %],[% } %][% } %]],
								// [% print $#im_fonts+1; %] fonts installed
								"imagemagick_fonts"  : [ [% foreach (0..$#im_fonts) { %]"$im_fonts[$_]"[% if ($_ != $#im_fonts){ %],[% } %][% } %]]
						    }
    }
JSON

}
