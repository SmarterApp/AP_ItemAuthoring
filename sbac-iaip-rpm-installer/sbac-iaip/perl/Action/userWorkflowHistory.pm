package Action::userWorkflowHistory;

use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  my $debug = 1;

  my $this_url = "${orcaUrl}cgi-bin/userWorkflowHistory.pl";

  #warn "userWorkflowHistory.pl: user = $user->{id}";

  my $items = &getItemsByUser( $dbh, $user->{id}, $in{itemBankId} );

  my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>User History</title>
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
    <div class="title">Your Recent Items</div>
		<table border="1" cellpadding="3" cellspacing="2">
		  <tr>
			  <th>Item</th><th>Date/Time</th><th>From State</th><th>To State</th><th>View</th>
			</tr>
END_HERE

foreach ( sort { $b cmp $a } keys %{$items} ) {
    $psgi_out .= <<END_HERE;
	  <tr>
		  <td>$items->{$_}{name}</td>
			<td>$_</td>
			<td>$items->{$_}{lastDevState}</td>
			<td>$items->{$_}{newDevState}</td>
			<td><input type="button" value="View" onClick="myOpen('itemViewWin','${orcaUrl}cgi-bin/itemContentView.pl?itemId=$items->{$_}{id}',600,500);" /></td>
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
