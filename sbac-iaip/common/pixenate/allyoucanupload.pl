#!/usr/bin/perl
use strict;
use LWP::Simple qw(!head);
use CGI ':standard';
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;

my $ua = LWP::UserAgent->new();

my $imgfile = param('image');
#my $imgfile = $ARGV[0];

my $request = POST "http://allyoucanupload.webshots.com/uploadcomplete",
  Content_Type => 'form-data',
  Content => [
				  "imagesCount" => 1,
				  "images[0].submittedPhotoSize" => "100%",
				  "images[0].fileName" => [$imgfile]
				 ];

my $response = $ua->request($request);
 
my $redirectedUrl = $response->headers()->{location};

my $req2 = GET "$redirectedUrl";
$response = $ua->request( $req2 );

my $content = $response->content();
#
# In it's current form this is a hack
# CNET will hopefully release an API for the allyoucanupload service
# so that scraping will not be necessary
#

my ($original) = $content =~ /direct link to image<\/b>\s+<div class="snippetHolder">\s+<input\s.+value="(.*)"/;

if ($original){
   $request = GET "http://tinyurl.com/api-create.php?url=$original";
   $response = $ua->request($request);
   $original = $response->content();
}
print "Content-type: text/html\n\n";
print "{original_image: \"$original\"}";


