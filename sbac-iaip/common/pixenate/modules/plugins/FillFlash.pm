package FillFlash;
use strict;
use PXN8 ':all';

sub fill_flash 
{
  my ($image, %params) = @_;
  my $brighter = $image->Clone();
  $image->Composite(image=>$brighter,compose=>"Screen", opacity=> "50%");
  return $image;
}
AddOperation('fill_flash', \&fill_flash);
1;
