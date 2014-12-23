package SpiritLevel;
use strict;
use PXN8 ':all';

sub spiritlevel 
{
	 my ($image, %params) = @_;
	 my $opposite = $params{y1} > $params{y2}?($params{y1} - $params{y2}):$params{y2} - $params{y1};
	 my $adjacent = $params{x1} > $params{x2}?($params{x1} - $params{x2}):$params{x2} - $params{x1};
  
	 my $hypotenuse = sqrt(($opposite * $opposite) + ($adjacent * $adjacent));
  
	 my $sineratio = $opposite/$hypotenuse;
	 
	 my $RAD2DEG = 57.2957795;
	 
	 my $rads = atan2($sineratio, sqrt(1 - $sineratio * $sineratio));
	 
	 my $degrees = $rads * $RAD2DEG;
	 if ($params{y1} < $params{y2}){
		  $degrees = 360 - $degrees;
	 }

	 $image->Rotate(degrees => $degrees);
  
	 return $image;

}
AddOperation('spiritlevel', \&spiritlevel);
1;
