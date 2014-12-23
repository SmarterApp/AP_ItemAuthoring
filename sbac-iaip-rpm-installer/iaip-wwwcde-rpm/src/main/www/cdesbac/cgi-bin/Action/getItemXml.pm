package Action::getItemXml;

use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  my $debug = 1;


  my $psgi_out = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
  $psgi_out .= &getItemXml( $dbh, $in{itemId} );

  return [ $q->psgi_header(
               -type       => "text/xml",
               -attachment => 'item.xml'),
           [ $psgi_out ]];
}
1;
