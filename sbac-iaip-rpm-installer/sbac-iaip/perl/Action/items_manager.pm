package Action::items_manager;

use lib qw( CDE/lib );
use ItemsManager;

sub run {

  our $q = shift;
  our $dbh = shift;

  $q->param(-name => 'action', -values => 'displaySearchMenu') unless $q->param('action');

  our $cde = new ItemsManager( cgi => $q, dbh => $dbh );

  return [ $q->psgi_header('text/html'), [ $cde->run() ] ];

}
1;
