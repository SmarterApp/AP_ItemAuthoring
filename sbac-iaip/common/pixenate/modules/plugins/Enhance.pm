package Enhance;
use strict;
use PXN8 ':all';
use Image::Magick;

sub instant_fix 
{
  my ($image, %params) = @_;
  $image->Normalize();
  $image->Enhance();
  return $image;
}
AddOperation('instant_fix', \&instant_fix);

sub normalize
{
  my ($image, %params) = @_;
  $image->Normalize();
  return $image;
}
sub enhance
{
  my ($image, %params) = @_;
  $image->Enhance();
  return $image;
}

AddOperation('normalize', \&normalize);
AddOperation('enhance', \&enhance);

1;
