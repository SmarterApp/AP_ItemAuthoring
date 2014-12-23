package Action::itemMetafiles;

use Item;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  my $item = new Item( $dbh, $in{itemId} );
  my $files = $item->getMetafiles();


  my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Metafiles</title>
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
    <div class="title">Item Metafiles</div>
		<p><a href="#" onClick="myOpen('uploadWin','${orcaUrl}cgi-bin/itemMetafileUpload.pl?itemId=$in{itemId}',600,400);">Upload</a>
		</p>
    <table border="1" cellpadding="2" cellspacing="2">
		  <tr>
			  <th>User</th><th>Time</th><th>State</th><th>View</th><th width="400">Comment</th>
			</tr>
END_HERE

  foreach ( sort { $b cmp $a } keys %{$files} ) {
    $files->{$_}{comment} =~ s/\r?\n/<br \/>/g;
    $psgi_out .= <<END_HERE;
	  <tr>
		  <td>$files->{$_}{lastName}, $files->{$_}{firstName}</td>
			<td>$_</td>
			<td>$files->{$_}{devState}</td>
			<td><a href="#" onClick="myOpen('commentWin','$files->{$_}{view}',800,600);">View</a></td>
			<td>$files->{$_}{comment}</td>
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
