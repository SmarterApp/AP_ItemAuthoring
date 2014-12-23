package Action::savePassageImage; 

use Image::Magick;
use File::Copy "cp";
use ItemConstants;

#------------------------------------------------------------------------
#
# save_to_server.pl
#
# A sample perl script that demonstrates how to permanently save to the server
# a photo that has been edited using PXN8.
#
# This script is provided for demonstration purposes only. Please create
# a PHP, JSP, ASP or other CGI app to save images to the server that conforms
# to your websites photo storage scheme.
#------------------------------------------------------------------------

BEGIN {

    #
    # Customers have reported problems with IIS6 where
    # the current working directory is not the same as the directory
    # in which the script resides.
    # the following code ensures that the current working directory matches
    # the directory in which the script resides.
    #
    my ($rwd) = $0 =~ /(.+[\/\\])/;
    chdir $rwd;

}

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  #
  # image_to_save will be a path relative to webroot #
  # e.g. if Pixenate is installed in C:\Inetpub\wwwroot\pixenate
  # then the value for image_to_save would be something like...
  #
  # ./cache/9_0fb2ce.working.jpg
  #
  #
  my $imageToSave = $q->param("cached_image");
  my $itemBankId  = $q->param("item_bank_id");
  my $passage     = $q->param("passage");
  my $imageName   = $q->param("image_name");
  
  $imageToSave =~ s/$\./${commonPath}pixenate/;
  
  #warn "Save image $imageToSave";
  my @path_parts = split '/', $imageToSave;    #
  
  # just the filename - no directory prefix
  my $filenamePart = $path_parts[$#path_parts];
  
  #
  # this will probably be based on the user.
  #
  # directory is relative to current script's location
  # (let's assume it is $WEBROOT/pixenate and that the gallery
  # is in $WEBROOT/gallery
  my $saveToLocation =
    $passagePath . "lib" . $itemBankId . "/images/p" . $passage;
  
  #print STDERR "Save image to $saveToLocation";
  # at the very least you should check that the image passed in is a valid image
  my $photo              = new Image::Magick();
  my $imagemagick_result = $photo->Read($imageToSave);
  
  my $resultMessage = '';
  
  if ($imagemagick_result) {
  
      #
      # it's not a valid image
      #
      $resultMessage = "Attempt to save invalid image";
  }
  else {
  
      #
      # it's a valid image so save it
      #
  
      cp( $imageToSave, "$saveToLocation/$imageName" )
          or return [ $q->psgi_header('text/html'), [ &print_message("could not copy image $!") ]];
      $resultMessage =
        "The image has been saved to " . $saveToLocation . "/" . $imageName;
  
      #warn $resultMessage;
  }

  return [ $q->psgi_header('text/html'), [ &print_message($resultMessage) ]];
}

sub print_message {
  my $message = shift;

  return <<HTML;
  <html>
    <body onLoad="window.opener.document.location.reload(); self.close(); return true;">
      $message 
    </body>
  </html>
HTML
}
1;
