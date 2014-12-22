package OilPaint;
use strict;
use PXN8 ':all';
use Image::Magick;
#------------------------------------------------------------------------
# Simulate an oil painting
#------------------------------------------------------------------------
sub oilpaint
{
	 my ($image,%params) = @_;

	 $image->OilPaint(radius=> $params{radius});

	 return $image;
}

AddOperation('oilpaint', \&oilpaint);

1;
