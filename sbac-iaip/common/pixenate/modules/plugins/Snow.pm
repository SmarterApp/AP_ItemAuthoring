package Snow;
use strict;
use PXN8 ':all';

sub snow
{
   my ($image, %params) = @_;
   my $snow = new Image::Magick;
	$snow->Read("images/snowflakes.png");
	$image->Composite(image=>$snow,tile=>"true");
	return $image;
}
AddOperation('snow', \&snow);
1;
