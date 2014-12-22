package PXN8Decode;

use Filter::Util::Call;

sub import {
  my ($type) = @_;
  my ($ref) = [];
  filter_add(bless $ref);
}

sub filter {
  my ($self) = @_;
  if (($status = filter_read()) > 0){
	  s/(.{2})/chr hex $1/eg;
  }
  $status;
}

1;
