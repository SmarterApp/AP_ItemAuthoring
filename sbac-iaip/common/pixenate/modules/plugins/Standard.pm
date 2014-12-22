package Standard;
use strict;
use PXN8 ':all';
use PXN8Debug;

#========================================================================
#
#  IMAGE OPERATIONS BEGIN HERE
#
#-----------------------------------------------------
# ADD AN INTERLACE EFFECT ON TOP OF THE SELECTED AREA
#-----------------------------------------------------
sub interlace 
{
	 my ($image,%params) = @_;
	 
	 my $opacity = $params{opacity};
	 $opacity = "60" unless defined $opacity;
  
	 my $color = $params{color};
	 $color = "#FFFFFF" unless defined $color;
	 
	 $params{left} = 0 if ($params{left} < 0);
	 $params{top} = 0 if ($params{top} < 0);
	 
	 my $imrc = undef;
  
	 my $cropped = undef;
	 my $overlay = 0;
	 
	 if ($params{width} > 0 && $params{height} > 0){
		  $cropped = $image->Clone;
		  $imrc = $cropped->Crop(width=>$params{width},height=>$params{height},x=>$params{left},y=>$params{top});
		  die "interlace failed: $imrc" if ($imrc);
		  $overlay = 1;
	 }else{
		  $cropped = $image;
	 }
	 
	 $params{width} = $cropped->Get("width");
	 
	 $params{height} = $cropped->Get("height");
	 
	 my $mattecolor =sprintf("%s%02X",$color,((100-$opacity)*2.56)); 
	 
	 for my $row (0..$params{height}/3){
		  
		  $cropped->Draw(primitive=>'line',
							  stroke=>'none',
							  points=>sprintf("%d,%d %d,%d",0,$row*3,$params{width},$row*3),
							  method=>'Floodfill',
							  fill=>"$mattecolor",
							  );
		  
	 }
	 
	 if ($overlay){
		  $imrc = $image->Composite(image=>$cropped,x=>$params{left},y=>$params{top});
		  die "interlace failed: $imrc" if ($imrc);
	 }
	 return $image;
}
# -----------------------------------------
# blur a region of the image
#
# -----------------------------------------
sub blur 
{
	 my ($image, %params) = @_;
	 
	 my $radius = $params{radius};
	 $radius = 1 unless $radius;
	 
	 my $blurred= $image;
	 if ($params{width} > 0 && $params{height} > 0){
		  
		  $blurred = $image->Clone;
		  $blurred->Crop(x=>$params{left},
							  y=>$params{top},
                       width=>$params{width},
                       height=>$params{height});
	 }
	 $blurred->Blur(sprintf("0.0x%0.1f",$radius));
	 if ($params{width} > 0 && $params{height} > 0){
		  $image->Composite(image=>$blurred,
								  x=>$params{left},
								  y=>$params{top});
	 }
	 return $image;
}
#
# -----------------------------------------
# Crop an image
# -----------------------------------------
#
sub crop
{
	 my ($image, %params) = @_;
	 $image->Crop(width=>$params{width},
                 height=>$params{height},
                 x=>$params{left},
                 y=>$params{top});
	 return $image;
}
# -----------------------------------------
# whiten teeth (also works on eyeballs ;-)
#
# -----------------------------------------
sub whiten 
{
	 my ($image, %params) = @_;
	 my @pixels = $image->GetPixels(map=>"RGB",
											  x=>$params{left},y=>$params{top},
											  height=>$params{height},width=>$params{width});
	 
	 for my $r (0..$params{height}-1){
		  for my $c (0..$params{width}-1){
				my $i = (($r*$params{width})+$c)*3;
				my ($red,$green,$blue) = @pixels[$i..$i+2];
				
				if ($red >= 40960 &&
					 $red > $green &&
					 $green > $blue + 2048)
				{
					 $blue = $blue + (($green-$blue)/2);
					 if ($red < 61440){
						  $red += 2048;
						  $blue += 2048;
						  $green += 2048;
					 }
					 $image->Set(sprintf("pixel[%d,%d]",
												$params{left}+$c,
												$params{top}+$r)=>sprintf("#%02X%02X%02X",
																				  $red/256,
																				  $blue/256,
																				  $green/256));
				}
		  }
	 }
	 return $image;
}

# -----------------------------------------
# Add a lomo effect to the image
# -----------------------------------------
sub lomoize
{
	 my ($image, %params)  = @_;
	 my $opacity = $params{opacity};
	 my $saturate = $params{saturate};

	 my $imrc = undef;
	 if ($saturate eq "true"){
		  $imrc = $image->Modulate(brightness=>120,
											saturation=>140,
											hue=>100,
											);
		  die "lomo error: $imrc\n" if ($imrc);
		  
		  PXN8Debug::log (__FILE__ . " MODULATE returned OK (sigh of relief)\n");
	 }
	 
	 my $iw = $image->Get("width");
	 my $ih = $image->Get("height");
		
	 my $diameter = $iw > $ih?$iw:$ih;
	 
	 my $bottom = $image->Clone;
	 PXN8Debug::log (__FILE__ ." opacity=$opacity\n");
	 $imrc = $bottom->Colorize(fill=>"#000000",opacity=>sprintf("%d%%",100-$opacity));
	 die "lomo error: $imrc\n" if ($imrc);
	 
	 my $mask = Image::Magick->new;
	 PXN8Debug::log ("lomo [5]\n");
	 $imrc = $mask->Read("images/mask256x256.jpg");
	 die "lomo error: $imrc\n" if ($imrc);
	 
	 $imrc = $mask->Resize(width=>$diameter,height=>$diameter);
	 die "lomo error: $imrc\n" if ($imrc);
	 
	 $imrc = $mask->Crop(x=>($diameter-$iw)/2, y=> ($diameter-$ih)/2,
								width=>$iw, height=> $ih);
	 die "lomo error: $imrc\n" if ($imrc);
	 
	 $imrc = $bottom->Composite(image=>$image,mask=>$mask);
	 die "lomo error: $imrc\n" if ($imrc);
	 
	 return $bottom;
}

# -----------------------------------------
# Change brightness, hue and saturation
# -----------------------------------------
sub brightness_saturation_hue
{
	 my ($image,%params) = @_;
	 
	 my $brightness = $params{brightness};
	 my $saturation = $params{saturation};
	 my $hue = $params{hue};
	 my $contrast = $params{contrast};
	 
	 PXN8Debug::log (__FILE__ . " ABOUT TO CALL MODULATE\n");
	 my $imrc = $image->Modulate(brightness=>$brightness, 
									  saturation=>$saturation, 
									  hue=>$hue,
									  );
	 PXN8Debug::log (__FILE__ . " MODULATE returned OK\n");
	 
	 die "bsh error: $imrc\n" if ($imrc);

	 if ($contrast == +1){
		  $image->Contrast(sharpen=>"True");
	 }
	 if ($contrast == +2){
		  $image->Contrast(sharpen=>"True");
		  $image->Contrast(sharpen=>"True");
	 }
	 if ($contrast == +3){
		  $image->Contrast(sharpen=>"True");
		  $image->Contrast(sharpen=>"True");
		  $image->Contrast(sharpen=>"True");
	 }
	 if ($contrast == -1){
		  $image->Contrast(sharpen=>"False");
	 }
	 if ($contrast == -2){
		  $image->Contrast(sharpen=>"False");
		  $image->Contrast(sharpen=>"False");
	 }
	 if ($contrast == -3){
		  $image->Contrast(sharpen=>"False");
		  $image->Contrast(sharpen=>"False");
		  $image->Contrast(sharpen=>"False");
	 }
	 
	 return $image;
	 
}

# -----------------------------------------
# Resize the image
# -----------------------------------------
sub resize 
{
	 my ($image, %params) = @_;
	 my $width = $params{width};
	 my $height = $params{height};
#
#   wph 20060127
#   commenting this out as it's now product
#
# 	 if ($width > 1600 || $height > 1600){
# 		  my $requested_width = $width;
# 		  $width = 1600;
# 		  $height = $height*1600/$requested_width;
# 	 }
	 
	 $image->Resize(width=>$width,height=>$height);
	 
	 return $image;
}


# -----------------------------------------
# make the image black and white
# -----------------------------------------
sub grayscale
{
	 my ($image, %params) = @_;
	 $image->Quantize(colorspace=>"Gray");
	 return $image;
}

# -----------------------------------------
# make the image sepia toned
# -----------------------------------------
sub sepia
{
	 my ($image, %params) = @_;
	 my $color = $params{color};

	 my $overlay = $image->Clone;
		
	 
	 $overlay->Colorize(fill=>$color,opacity=>"100%");
	 $image->Quantize(colorspace=>"Gray");
	 $image->Composite(image=>$overlay,compose=>"Overlay");

	 return $image;
}

# -----------------------------------------
# add a lens filter 
# -----------------------------------------
sub filter 
{
	 my ($image, %params) = @_;
	 my $color = $params{color};
	 my $opacity = $params{opacity};

	 my $w = $image->Get("width");
	 
	 my $filter = Image::Magick->new;
	 
	 $filter->Set(size=>$w."x".$params{top});
	 $filter->ReadImage("gradient:$color-none");
		
	 $filter = $filter->Fx(channel=>'alpha',
								  expression=>"u/100*$opacity");
	 
	 $image->Composite(image=>$filter);
	 
	 return $image;	 
}

sub fetch 
{
  my ($image, %params) = @_;
  my $imgParam = $params{image};
  PXN8Debug::log("before : $imgParam\n");
  $imgParam =~ s/%([0-9A-F]{2})/chr (hex $1)/eg;
  PXN8Debug::log("after : $imgParam\n");

  #
  # try to open the explicit filepath
  #
  if (exists $params{filepath}){
	 if (-e $params{filepath}){
		my $imrc = $image->Read($params{filepath});
		if ($imrc){
		  die "Error reading image filepath $params{filepath}\n $imrc";
		}else{
		  return $image;
		}
	 }else{
		die "Non-existent image filepath ($params{filepath})";
	 }
  }
  #
  # try to open the URL
  #
  if ($imgParam =~ /^http:\/\// or $imgParam =~ /^ftp:\/\//){

	 return fetchFromWeb($image, $imgParam,$params{target});

  }
  # 
  # we don't know if it's a URL or filepath
  #

  my $imageURL = $imgParam;

  if ($imgParam =~ /^\//){
	 #
	 # file is relative to web root 
	 # adjust the filename accordingly
	 #

	 # prepend the . so we don't look in / root dir
	 # this solution assumes that pxn8.pl will always be in webroot  !!!
	 # todo : fix this so that it works when pxn8 is installed in a directory
	 # other than webroot.
	 #
	 my $prefix = "";
	 foreach (grep /.+/, split '/', $params{pxn8root}){
		$prefix .= "../";
	 }
	 if ($prefix eq ""){
		$prefix = ".";
	 }
	 $imgParam = $prefix . $imgParam;
  }

  if (-e $imgParam)	 {
	 PXN8Debug::log("Attempting to fetch image from filesystem: $imgParam\n");

	 my $imrc = $image->Read($imgParam);
	 if ($imrc){
		die "Error reading image file $imgParam \n $imrc";
	 }else{
		return $image;
	 }
  }else{
	 use CGI ':standard';
	 my $webroot = url(-base => 1);
	 PXN8Debug::log("Attempting to fetch image from webserver: $imageURL\n");

	 return fetchFromWeb($image, "$webroot/$imageURL",$params{target});
  }
}

sub fetchFromWeb 
{
  my ($image, $url,$file) = @_;
  #
  # test that the directory is writeable !
  # getstore returns a 500 if the request succeeded but the file can't be written.
  # The most likely cause of a file write failure is directory permissions
  #
  my @filenameparts = split '/', $file;
  my $directorypart = join '/', @filenameparts[0..$#filenameparts-1];
  unless (-w $directorypart){
	 die "Cannot write temporary files to directory: $directorypart" ;
  }
  #
  # it's a URL
  #
  my $rc = LWP::Simple::getstore($url,$file);
  if (-e $file){
	 my $imrc = $image->Read($file);
	 if ($imrc){
		die "Retrieved image $url but could not open file: $imrc";
	 }else{
		return $image;
	 }
  }else{
	 die ("Could not retrieve image [$file] from the web. " .
			  "Remote server returned: $rc while trying to access [$url] ($!)");
	 return 0;
  }
}

AddOperation('fetch', \&fetch);
AddOperation('interlace', \&interlace);
AddOperation('blur', \&blur);
AddOperation('crop', \&crop);
AddOperation('whiten', \&whiten);
AddOperation('lomo', \&lomoize);
AddOperation('bsh', \&brightness_saturation_hue);
AddOperation('resize', \&resize);
AddOperation('grayscale', \&grayscale);
AddOperation('sepia', \&sepia);
AddOperation('filter', \&filter);

1;
