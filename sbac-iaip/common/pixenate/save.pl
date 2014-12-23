#!/usr/bin/perl -I./modules
use strict;
use CGI ':standard';
use POSIX;
my $query = CGI->new;

my $image = $query->param('image');
my $originalFilename = $query->param('originalFilename');
$originalFilename = (reverse(split (/[\/\\]/, $originalFilename)))[0];
my $timeStr = strftime("%Y%m%d%H%M%S",gmtime());
my $filename = "$originalFilename$timeStr" . ".jpg";

#my $filename = $image;
#$filename =~ s/.*[\/\\](.*)/$1/;

print $query->header(-type=>'application/octet-stream',
							-attachment => "$filename");

open (JPEG, $image);
my $buff = "";
binmode JPEG;
binmode STDOUT;
while (read(JPEG, $buff, 16384)){
  print STDOUT $buff;
}
close JPEG;

