package Action::standards_manager;

use lib qw( CDE/lib );
use StandardsManager;

sub run {

  our $q = shift;
  our $dbh = shift;

  $q->param(-name => 'action', -values => 'displayEditor') unless $q->param('action');

  my $cde = new StandardsManager( cgi => $q, dbh => $dbh );

  if( $q->param('action') eq 'PDF' ) {
    return [ $q->psgi_header( -type => 'application/pdf' ), [ $cde->run() ]];
  }
  elsif( $q->param('action') eq 'exportHierarchyXML' ) {
    return [ $q->psgi_header( -type => 'text/xml', -attachment => 'hierarchy.xml' ), [ $cde->run() ]];
  }
  elsif( $q->param('action') =~ /createHD|reorderSiblings/ ) {
    return [ $q->psgi_header( -type => 'application/json', -charset => 'utf-8' ), [ $cde->run() ]];
  }
  else {
    return [ $q->psgi_header( -type => 'text/html' ), [ $cde->run() ]];
  }
}
1;
