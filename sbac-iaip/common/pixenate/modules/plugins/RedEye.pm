package RedEye;
use strict;
use PXN8 ':all';
use Image::Magick;
#------------------------------------------------------------------------
# FIX red eye
#------------------------------------------------------------------------
sub fix_red_eye
{
	 my ($image,%params) = @_;

	 my $cx = $params{left} + ($params{width}/2);
	 my $cy = $params{top} + ($params{height}/2);
	 my $rx = $params{width}/2;
	 my $ry = $params{height}/2;


	 my $red_channel = $image->Clone();

	 $red_channel->Separate(channel=>"Red");

	 my @pixels = $red_channel->GetPixels(map=>"RGB",x  => $params{left},y  => $params{top},height => $params{height},width => $params{width});

	 my $darkest = darkest_in_region (@pixels);
	 
	 $red_channel->Draw ( primitive => "ellipse", 
								 fill => sprintf("#%02X%02X%02X",$darkest,$darkest,$darkest),
								 stroke=>"none",
								 points => "$cx, $cy $rx, $ry 0,360");


	 $image->Composite(image=>$red_channel, compose=>"CopyRed");
	 
	 return $image;
}

sub darkest_in_region {
	 my @region = @_;
	 my $result = 256;
	 foreach (0..($#region / 3)){
		  my ($r,$g,$b) = @region[$_..$_+2];
		  $r = $r / 256;
		  if ($r < $result){
				$result = $r;
		  }
	 }
	 return $result;
}

AddOperation('redeye', \&fix_red_eye);
1;
