package Charcoal;
use strict;
use PXN8 ':all';
use Image::Magick;
#------------------------------------------------------------------------
# Simulate a charcoal drawing
#------------------------------------------------------------------------
sub charcoal
{
	 my ($image,%params) = @_;

	 $image->Charcoal(sigma=>1.0,
							radius=> $params{radius});

	 return $image;
}

AddOperation('charcoal', \&charcoal);

1;
