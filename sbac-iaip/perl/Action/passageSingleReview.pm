package Action::passageSingleReview;

use ItemConstants;
use Passage;
use PassageMediaTable qw(View_Mode);

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $this_url = "${orcaUrl}cgi-bin/passageSingleReview.pl";

  our $sth;
  our $sql;
  
  return [ $q->psgi_header('text/html'), [ &print_preview(\%in) ]];
}

### ALL DONE! ###

sub print_preview {
  my $psgi_out = '';

    my $params = shift;

    my $psg = new Passage( $dbh, $params->{passageId} );

    my $passageApprover = $psg->getApprover();
    my $passageWriter   = $psg->{authorName} || '';
    my $devStateName    = $dev_states{ $psg->{devState} };
    my $contentAreaName = $const[$OC_CONTENT_AREA]->{ $psg->{contentArea} };
    my $gradeLevelName  = $const[$OC_GRADE_LEVEL]->{ $psg->{gradeLevel} };
    my $bankName        = $psg->{bankName};

    my $mediaTable = new PassageMediaTable();

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/uir.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css" />
    @{[$mediaTable->get_style_library_includes()]}
    @{[$mediaTable->get_js_library_includes(1)]}
    <script language="JavaScript">
    <!--
      \$(document).ready(function() {
          @{[$mediaTable->get_jquery_ready_function()]}
        }
      );

      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(350,150); 
	return true; 
      }
    //-->
    </script>
  </head>
  <body onLoad="parent.menuFrame.document.getElementById('action_accept').style.display='inline';">
    <table class="no-style" border="0" cellpadding="0" cellspacing="0">
    <tr><td>
      <div class="title">Passage:&nbsp;&nbsp;<b>$psg->{name}</b>&nbsp;&nbsp;&lt;$psg->{bankName}&gt;</div>
      Summary:&nbsp;&nbsp;$psg->{summary}
			<br /><br />
			$psg->{content}
    </td></tr>
    <tr><td>
    @{[$mediaTable->draw($psg, $mediaTable->find_media_for_passage($psg), View_Mode)]}
    </td></tr>
    <tr><td>
    <table border="1" cellspacing="3" cellpadding="1">
     <tr><td>Dev State:</td><td>${devStateName}</td></tr>
     <tr><td>Content Area:</td><td>${contentAreaName}</td></tr>
     <tr><td>Grade Level:</td><td>${gradeLevelName}</td></tr>
END_HERE

    unless ( $psg->{notes} eq '' ) {
        $psgi_out .= <<END_HERE;
     <tr>
       <td>Notes:</td><td><textarea name="notes" rows="8" cols="35">$psg->{notes}</textarea></td>
     </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
     <tr>
       <td>Writer:</td><td>${passageWriter}</td> 
     </tr>
     <tr>
       <td>Reviewer:</td><td>${passageApprover}</td> 
     </tr>
    </table>
    </td></tr>
    </table>
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
