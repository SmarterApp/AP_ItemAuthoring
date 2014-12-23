package Action::cde;

use lib qw( CDE/lib );
use CDE;

sub run {

  our $q = shift;
  our $dbh = shift;

  $q->param(-name => 'action', -values => 'startApp') unless $q->param('action');

  our $cde = new CDE( cgi => $q, dbh => $dbh );
  
  return [ $q->psgi_header('text/html'), [ $cde->run() ]];
}
1;
