package Flickr;
our $VERSION = '0.01';

use strict;
require Exporter;
our @ISA  = ("Exporter");

our @EXPORT_OK = qw(refering_image);
our %EXPORT_TAGS = (all => \@EXPORT_OK,);

sub refering_image
{
	 my ($query,$apikey) = @_;
	 my $result = "";
	 my $referer = $query->referer();
	 if ($referer =~ /flickr\.com/) {
		  # ---------------------------------------------------------
		  # have we arrived here from flickr ?
		  # if so use the image the visitor was looking at in flickr
		  # ---------------------------------------------------------
		  use LWP::Simple qw(!head);
		  my @matches = $referer =~ /(id=|\/)([0-9]{8,})[\/&]/;
		  if (@matches){
				my $photoid = $matches[1];
				my $flickrURL = sprintf("http://www.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=%s&photo_id=%s",
												$apikey,
												$photoid);
				
				# ------------------------------------------------------
				# flickr sends an XML response listing all the available
				# filesizes and associated urls for the image.
				# ------------------------------------------------------
				my $response = LWP::Simple::get($flickrURL);
				
				my $xml = Xanadb::XML::parseString($response);
				
				if (exists $xml->{rsp}->{sizes}){
					 my @sizes = @{$xml->{rsp}->{sizes}->{size}};
					 
					 my %urlsBySize = map {$_->{'@label'} => $_->{'@source'} } @sizes;
					 if (exists $urlsBySize{'Medium'}){
						  $result = $urlsBySize{Medium};
					 }
				}
				
		  } # visitor was looking at a flickr photo
		  
	 } # visitor arrived here via flickr
	 return $result;
}
