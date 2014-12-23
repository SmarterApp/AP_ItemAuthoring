#!/usr/bin/perl -I./modules
#-----------------------------------------------------------------------
#
# (c) Copyright 2005-2006 SXOOP Technologies Ltd.
#
# All rights reserved.
#
#-----------------------------------------------------------------------

use strict;
use CGI ':standard';
use CGI::Carp qw(carpout fatalsToBrowser);
use PerlTagsBasic;
use Digest::MD5;
use PXN8Debug;
# ------------------------------------
# read and evaluate configuration file
# ------------------------------------
open CONFIG, "<config.ini" 
  or die "Could not open configuration file config.ini $!\n";
no strict 'vars';
my $CONFIG = eval (join '',<CONFIG>);
close CONFIG;

$PXN8Debug::debug = $CONFIG->{DEBUG};

# ----------------------------
# set file upload size limit
# ----------------------------
$CGI::POST_MAX = $CONFIG->{CGI_POST_MAX};

my $query = new CGI();


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


my $server_port = $query->server_port();
my $server_name = $query->server_name();

# ----------------------------
# What image is to be edited ?
# ----------------------------

my $image = $query->param('image');

# ---------- START OF UPLOAD -------------

my $uploaded = 'false';

if ($query->param('filename') ne "") {

	 #------------------------------------------
	 # visitor is attempting to upload an image
	 #------------------------------------------
	 $uploaded = 'true';

	 my $filename = $query->param('filename');
	 my ($file_ext) = $filename =~ /(\.[a-zA-Z]+)$/;
	 $filename = sprintf("%s.jpg",
								Digest::MD5::md5_hex($filename . $query->remote_host() ));

	 my $upload_filehandle = $query->upload('filename');

	 if ($upload_filehandle){

		  #---------------------------------------
		  # save the uploaded image to the server
		  #---------------------------------------

		  my $filepath = "$CONFIG->{UPLOAD_PATH}/$filename";

		  open UPLOADFILE, ">$filepath" or die "Could not open file $filepath: $!\n";
		  
		  binmode UPLOADFILE;
		  while ( <$upload_filehandle> ){
				print UPLOADFILE;
		  }
		  close UPLOADFILE;
		  
		  use Image::Magick;
		  my $im = new Image::Magick();
		  my $imres = $im->Read($filepath);
		  if ($imres){
			 # its not a valid image !!!
			 PXN8Debug::log ("index.pl : about to remove invalid uploaded image [$filepath]\n");
			 unlink $filepath or die "Could not remove invalid file $filepath: $!";
			 PXN8Debug::log ("index.pl : removed image\n");
		  }else{
			 #
			 # must resize images that are too big to more manageable web dimensions
			 #
			 my $maxDim = 800;
			 my $iw = $im->Get('width');
			 my $ih = $im->Get('height');
			 my $resize = 0;
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
			 }
			 $imres = $im->Write(filename=>$filepath);
			 if ($imres){
				  print STDOUT "Content-type: text/plain\n\n";
				  print STDOUT "An error occurred during upload: $imres\n";
				  exit;
			 }
			 $image = "http://$server_name:$server_port/$filepath";
		  }
		  
		  #
		  # remove old files from the upload area
		  #
		  my %cache = map { $_ => (stat $_)[9] } glob ("$CONFIG->{UPLOAD_PATH}/*");
		  my $time = time();
		  foreach (keys %cache){
			 if ($time - $cache{$_} > $CONFIG{DELETE_UPLOADS_AFTER}){ 
				unlink $_; 
			 }
		  }

	 }
}
# ---------- END OF UPLOAD -------------


if ($image eq "")
{
	 # ------------------------------------------
	 # no image has been supplied as a parameter
	 # ------------------------------------------ 
	 my $referer = $query->referer();

	 if ($referer =~ /flickr\.com/)
	 {
		  # ---------------------------------------------------------
		  # have we arrived here from flickr ?
		  # if so use the image the visitor was looking at in flickr
		  # ---------------------------------------------------------
		  use LWP::Simple qw(!head);
		  my @matches = $referer =~ /(id=|\/)([0-9]{8,})[\/&]/;

		  if (@matches){
				my $photoid = $matches[1];
				my $flickrURL = sprintf("http://www.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=%s&photo_id=%s",
												$CONFIG->{FLICKR_APIKEY},
												$photoid);
				
				# ------------------------------------------------------
				# flickr sends an XML response listing all the available
				# filesizes and associated urls for the image.
				# ------------------------------------------------------
				my $response = LWP::Simple::get($flickrURL);
				
				my $xml = Xanadb::XML::parseString($response);
				
				if (exists $xml->{rsp}->{sizes}){
					 my @sizes = @{$xml->{rsp}->{sizes}->{size}};
					 
					 my %urlsBySize = map {$_->{'@label'} => $_->{'@source'} } @sizes;
					 if (exists $urlsBySize{'Medium'}){
						  $image = $urlsBySize{Medium};
					 }
				}

		  } # visitor was looking at a flickr photo

	 } # visitor arrived here via flickr

	 if ($image eq "")
	 {
		  # ----------------------------------------------------------
		  # if we are here then no image was supplied as a parameter
		  # and the visitor was not looking at a flickr photo.
		  # use a random default image
		  # ----------------------------------------------------------
		  my @images = @{$CONFIG->{DEFAULT_IMAGES}};
		  
		  $image = $images[rand() * scalar @images];
	 }
}

if ($image !~ /^http/){
  $image = "http://$server_name:$server_port/$image";
}

my @output = ();

my $template = $query->param('template');

if ($template eq "" || $template =~ /^upload/ || $template =~ /^cache/)
{
	 $template = $CONFIG->{EDIT_TEMPLATE};
}


print $query->header(-type=>'text/html');
	 


my $page = new PerlTagsBasic($query);
# ----------------------------------------------------------
# setup page variable before processing template
# ----------------------------------------------------------
$page->{image} = $image;
$page->{uploaded} = $uploaded;
$page->{CONFIG} = $CONFIG;

$page->process(filename=>$template,
					output=>\@output);
print @output;

exit;
