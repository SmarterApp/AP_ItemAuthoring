package Rotate;
use strict;
use PXN8 ':all';
use Image::Magick;
# -----------------------------------------
# Rotate the image
# -----------------------------------------
sub rotate 
{
	 my ($image, %params) = @_;

	 my $angle = $params{angle};
	 my $flipvt = $params{flipvt};
	 my $fliphz = $params{fliphz};
	 if ($flipvt eq "true"){
		  $image->Flip;
	 }
	 if ($fliphz eq "true"){
		  $image->Flop;
	 }
	 
	 $image->Rotate(degrees=>$angle);
	 
	 return $image;
}
AddOperation('rotate', \&rotate);
1;
