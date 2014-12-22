package Action::passageHistory;

use Passage;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  my $debug = 1;

  my $this_url = "${orcaUrl}cgi-bin/passageHistory.pl";

  my $passage = new Passage( $dbh, $in{passageId} );
  my $history = $passage->getHistory();

  my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Notes</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
		<script language="JavaScript">

      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
	return true; 
      }
		</script>
	</head>
  <body>
    <div class="title">Passage Edit History</div>
    <table border="1" cellpadding="2" cellspacing="2">
		  <tr>
			  <th>User</th><th>Time</th><th>State</th><th>View</th>
			</tr>
END_HERE

  foreach ( sort { $b cmp $a } keys %{$history} ) {
    $psgi_out .= <<END_HERE;
	  <tr>
		  <td>$history->{$_}{lastName}, $history->{$_}{firstName}</td>
			<td>$_</td>
			<td>$history->{$_}{devState}</td>
			<td><input type="button" value="View" onClick="myOpen('pdfWin','$history->{$_}{view}',700,500);" /></td>
		</tr>	
END_HERE
  }

  $psgi_out .= <<END_HERE;
    </table>
  </body>
</html>
END_HERE

  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
}
1;
