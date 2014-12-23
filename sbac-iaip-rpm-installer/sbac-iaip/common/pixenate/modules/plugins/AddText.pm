package AddText;
use strict;
use PXN8 ':all';

sub text 
{
  my ($image, %params) = @_;
  $image->Annotate(%params);
  return $image;
}

AddOperation('add_text', \&text);

1;
