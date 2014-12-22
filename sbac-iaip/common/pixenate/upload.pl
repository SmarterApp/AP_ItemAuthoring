#!/usr/bin/perl -I./modules
# ----------------------------------------------------------------------------
#
# (c) Copyright 2005-2006 SXOOP Technologies Ltd.
#
# All rights reserved.
#
# ----------------------------------------------------------------------------
use strict;

use CGI ':standard';
use CGI::Carp qw(carpout fatalsToBrowser);
use Digest::MD5;
use PXN8Debug;

# ------------------------------------
# read and evaluate configuration file
# ------------------------------------
open CONFIG, "<config.ini" 
  or die "Could not open configuration file config.ini $!\n";
no strict 'vars';
my $CONFIG = eval (join '',<CONFIG>);
use strict 'vars';
close CONFIG;

$PXN8Debug::debug = $CONFIG->{DEBUG};
# ----------------------------
# set file upload size limit
# ----------------------------
$CGI::POST_MAX = $CONFIG->{CGI_POST_MAX};

my $query = new CGI();

my $nextPage = $query->param("next_page");
my $image_param_name = $query->param("image_param_name");
my $hires_image_param_name = $query->param("hires_image_param_name");
my $pxn8root = $query->param("pxn8_root");
my $maxDim = $query->param("max_dim");

my $cgi_error = $query->cgi_error();

if ($cgi_error =~ /^413/){
  my $kbLimit = $CONFIG->{CGI_POST_MAX}/1024;
  
  print STDOUT "Content-type: text/html\n\n";
  print STDOUT "<html><body>\n";
  print STDOUT "You cannot upload images greater than $kbLimit Kilobytes in size!";
  print STDOUT "<br/>Click the browser's back button to continue...";
  print STDOUT "</body></html>";
  exit;
}

my $upload_filehandle = $query->upload('filename');

my $filename = $query->param('filename');

#
# bug fix 20060721 save.pl should use original filename
# when saving image to disk.
#
my $originalFilename = $filename; 
my ($file_ext) = $filename =~ /(\.[a-zA-Z]+)$/;
$filename = sprintf("%s.jpg",
						  Digest::MD5::md5_hex($filename . $query->remote_host() ));


my $filepath = "";
#
# flag to indicate if image had to be resized
#
my $resize = 0;

if ($upload_filehandle){

  #---------------------------------------
  # save the uploaded image to the server
  #---------------------------------------
  
  $filepath = "$CONFIG->{CACHE_DIR}/$filename";
  
  open UPLOADFILE, ">$filepath" or die "Could not open file $filepath: $!\n";
  
  binmode UPLOADFILE;
  while ( <$upload_filehandle> ){
	 print UPLOADFILE;
  }
  close UPLOADFILE;
		  
  use Image::Magick;
  my $im = new Image::Magick();
  my $imres = $im->Read($filepath);
  my $original_image = $im->Clone();

  if ($imres){
	 # its not a valid image !!!
	 PXN8Debug::log ("upload.pl : about to remove invalid uploaded image [$filepath]\n");
	 unlink $filepath or die "Could not remove invalid file $filepath: $!";
	 PXN8Debug::log ("upload.pl : removed image\n");
  }else{

	 
	 if ($maxDim){
		#
		# must resize images that are too big to more manageable web dimensions
		#
		my $iw = $im->Get('width');
		my $ih = $im->Get('height');
		if ($iw > $ih){
		  if ($iw > $maxDim){
			 $ih = $ih * ($maxDim / $iw);
			 $iw = $maxDim;
			 $resize = 1;
		  }
		}else{
		  if ($ih > $maxDim){
			 $iw = $iw * ($maxDim/ $ih);
			 $ih = $maxDim;
			 $resize = 1;
		  }
		}
		
		if ($resize == 1){
		  $im->Resize(width=>$iw, height=>$ih);
		  $imres = $im->Write(filename=>"$CONFIG->{CACHE_DIR}/small_$filename");
		}
	 }
	 $imres = $original_image->Write(filename=>$filepath);
	 if ($imres){
		print STDOUT "Content-type: text/plain\n\n";
		print STDOUT "An error occurred during upload: $imres\n";
		exit;
	 }
  }
}

my $server_name = $query->server_name();
my $server_port = $query->server_port();
my $image_param_value = undef;
my $newpage = "http://$server_name:$server_port$nextPage?";

if ($resize && $hires_image_param_name){
  $image_param_value = "$pxn8root/$CONFIG->{CACHE_DIR}/small_$filename";
}else{
  $image_param_value = "$pxn8root/$filepath";
}

$newpage .= "$image_param_name=$image_param_value&";
if ($hires_image_param_name && $resize){
  $newpage .= "$hires_image_param_name=$pxn8root/$filepath&";
}
$newpage .= "originalFilename=$originalFilename";

PXN8Debug::log ("upload.pl : about to redirect to: [$newpage]\n");

#
# On IIS 5.1 The -nph flag must be set so that the redirect works properly.
# unfortunately, setting the nph flag breaks on Apache so I need to detect the 
# server software
#
my $nph = $ENV{SERVER_SOFTWARE} !~ /Apache/i;

print $query->redirect(-uri=>$newpage,
							  -status=>302,
							  -nph=>$nph
							 );

exit(0);


