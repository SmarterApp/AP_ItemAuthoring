package Action::passageNotes;

use strict;
use CGI;
use DBI;
use ItemConstants;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  my $debug = 1;

  my $this_url = "${orcaUrl}cgi-bin/passageNotes.pl";

  my $sql =
    "SELECT pst.*, u.* FROM passage_status AS pst, user AS u"
  . " WHERE pst.p_id=$in{passageId} AND pst.p_notes != '' AND pst.ps_u_id=u.u_id"
  . " ORDER BY pst.ps_timestamp DESC";
  my $sth = $dbh->prepare($sql);
  $sth->execute();

  my $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Notes</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
		<script language="JavaScript">
		  function copyNotes() {
		   if(parent.document.createPassage != undefined && parent.document.createPassage.passageNotes !=undefined &&   parent.document.createPassage.passageNotes.value !=undefined){
			  document.form1.notes.value = parent.document.createPassage.passageNotes.value;
			  }
			  else{
			  document.form1.notes.value = parent.document.createPassage.passageNote.value;
			  }
			}

			function updateNotes( ) {
			if(parent.document.createPassage.passageNotes==undefined){
		    parent.document.createPassage.passageNote.value = document.form1.notes.value;  
		    }else{
		    parent.document.createPassage.passageNotes.value = document.form1.notes.value;
		    }
			}  
		</script>
	</head>
  <body onLoad="copyNotes();">
    <div class="title">Your Notes</div>
		<form name="form1">
		<table border="1" cellpadding="2" cellspacing="2">
		  <tr><td><textarea name="notes" rows="5" cols="60" onBlur="updateNotes();"></textarea></td></tr>
		</table>
		</form>
    <br />
    <div class="title">Previous Notes</div>
    <table border="1" cellpadding="2" cellspacing="2">
		  <tr>
			  <th>User</th><th>Time</th><th>State</th><th>Notes</th>
			</tr>
END_HERE

while ( my $row = $sth->fetchrow_hashref ) {
    $row->{p_notes} =~ s/\r?\n/<br \/>/g;
    $psgi_out .= <<END_HERE;
	  <tr>
		  <td>$row->{u_last_name}, $row->{u_first_name}</td>
			<td>$row->{ps_timestamp}</td>
			<td>$dev_states{$row->{ps_last_dev_state}}</td>
			<td>$row->{p_notes}</td>
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