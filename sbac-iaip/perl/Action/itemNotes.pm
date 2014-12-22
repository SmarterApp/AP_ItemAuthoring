package Action::itemNotes;

use Item;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  my $debug = 1;

  my $this_url = "${orcaUrl}cgi-bin/itemNotes.pl";


  my $item = new Item( $dbh, $in{itemId} );
  my $notes = $item->getAllNotes();
   
  my $psgi_out = <<END_HERE;
<!DOCTYPE HTML>
<html>
  <head>
    <title>Item Notes</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
		<script language="JavaScript">
		  function copyNotes() {		 
		 if(parent.document.itemCreate.itemNotes!=undefined){		 
			  	  document.form1.notes.value = parent.document.itemCreate.itemNotes.value;
			  
		  }else{
		  document.form1.notes.value =parent.document.itemCreate.itemNote.value;
		  }
			}

			function updateNotes() {			
			if(parent.document.itemCreate.itemNotes==undefined){			
		      parent.document.itemCreate.itemNote.value = document.form1.notes.value;  
		    }else{		    
		      parent.document.itemCreate.itemNotes.value = document.form1.notes.value; 
		    }
		    
			}  
		</script>
	</head>
  <body onLoad="copyNotes();">
    <div class="title">Your Notes</div>
		<form name="form1">
		<table border="1" cellpadding="2" cellspacing="2" class="no-style"> 
		  <tr><td><textarea name="notes" rows="5" cols="60" onBlur="updateNotes();"></textarea>
		</table>
		</form>
    <br />
    <div class="title">Previous Notes</div>
    <table border="1" cellpadding="2" cellspacing="2" class="no-style">
		  <tr>
			  <th>User</th><th>Time</th><th>State</th><th width="400">Notes</th>
			</tr>
END_HERE

  foreach ( sort { $b cmp $a } keys %{$notes} ) {
    $notes->{$_}{notes} =~ s/\r?\n/<br \/>/g;
    $psgi_out .= <<END_HERE;
	  <tr>
		  <td>$notes->{$_}{lastName}, $notes->{$_}{firstName}</td>
			<td>$_</td>
			<td>$notes->{$_}{devState}</td>
			<td>$notes->{$_}{notes}</td>
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