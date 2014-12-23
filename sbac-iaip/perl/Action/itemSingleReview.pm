package Action::itemSingleReview;

use ItemConstants;
use Item;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $sth;
  our $sql;

  our $userType = $review_type_map{$user->{reviewType}};
  our $isAdmin = $user->{adminType} ? 1 : 0;
 
  return [ $q->psgi_header('text/html'), [ &print_item(\%in) ] ];
}

### ALL DONE! ###

sub print_item {
  my $psgi_out = '';

    my $params = shift;

    my $item = new Item( $dbh, $params->{itemId} );

    my $c   = $item->getDisplayContent();
    my $gle = $item->getGLE();

    my $documentReadyFunction = $c->{documentReadyFunction};

    my $formatName       = $item_formats{ $item->{format} }              || '';
    my $difficultyName = $difficulty_levels{ $item->{difficulty} } || '';
    my $itemApprover   = $item->getApprover();
    my $itemWriter     = $item->{authorName}                       || '';
    my $devStateName   = $dev_states{ $item->{devState} };
    my $minorEditChecked =
      ( exists( $item->{$OC_MINOR_EDIT} ) && $item->{$OC_MINOR_EDIT} )
      ? 'CHECKED'
      : '';

    my $gleName = ( defined $gle->{name} ? $gle->{name} : '' );
    $gleName =~ s/GLE//;
    my $gleText = ( defined $gle->{text} ? $gle->{text} : '' );
    $gleText =~ s/\r?\n/<br \/>/g;

    my $charDisplay = "";

    foreach (@ctypes) {
        $charDisplay .=
            '<tr><td>'
          . ( $labels[$_] || '' ) . '</td>'
          . '<td><b>'
          . ( $const[$_]->{ $item->{$_} || '' } || '' )
          . '</b></td></tr>';

    }

    my $passages  = $item->getPassages();
    my $rubrics   = $item->getRubrics();
    my $metafiles = $item->getMetafiles();

    my $mediaAssets = &getMediaAssetAttributes($dbh, $item->{id});
    if (scalar(@{$mediaAssets})>0) {
       $documentReadyFunction .= '$("#noMediaMessage").hide();';
    } 

    my $itemCssLink = $item->getCssLink();

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <title>Item Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css">
    <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
    ${itemCssLink}
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
    <script type="text/javascript" src="${commonUrl}mathjax/MathJax.js?config=MML_HTMLorMML"></script>
    <script type="text/javascript">  

      \$(document).ready(function() {

        ${documentReadyFunction}
      });
    </script>
    <style type="text/css">
      td { vertical-align: middle; }

  </style>
	<script language="JavaScript">
      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
	return true; 
      }
  </script>
  </head>
  <body onLoad="parent.menuFrame.document.getElementById('action_accept').style.display='inline';">
END_HERE

    if ( $userType eq 'content_specialist' || $userType eq 'editor' ) {
        $psgi_out .= <<END_HERE;
	    <p><a href="#" onClick="myOpen('printWin','${orcaUrl}cgi-bin/itemPrintList.pl?viewType=4&myAction=print&autoPrint=1&itemBankId=$item->{bankId}&itemExternalId=$item->{name}&view_itemId=1&view_itemContent=1',600,600);">Print Item</a>
END_HERE
    }

    if ($USE_ITEM_XML) {
        $psgi_out .= <<END_HERE;
		&nbsp;&nbsp;&nbsp;<a href="${orcaUrl}cgi-bin/getItemXml.pl?itemId=$item->{id}">Get Item XML</a>
END_HERE
    }

    $psgi_out .= <<END_HERE;
			</p>
      <p>Item:&nbsp;&nbsp;<b>$item->{name}</b>&nbsp;&nbsp;&lt;$item->{bankName}&gt;<br />
      Description:&nbsp;&nbsp;$item->{description}</p>
			<p><form name="form1"><input type="checkbox" name="minorEdit" value="1" ${minorEditChecked} />&nbsp;Minor Edit?</form></p>
END_HERE

    if ( $gleName ne '' ) {
        $psgi_out .= <<END_HERE
     <table class="no-style" border="1" cellspacing="3" cellpadding="3" width="455">
       <tr><th align="center">GLE ${gleName}</th></tr>
       <tr><td>${gleText}</td></tr>
     </table>
     <br />
END_HERE
    }

    $psgi_out .= <<END_HERE;
    <br />
    $c->{itemBody}
END_HERE

    $psgi_out .= "<br />".&getMediaTableHtml($mediaAssets);

    $psgi_out .= <<END_HERE;
    <br />
    $c->{distractorRationale}
    <br />
    $c->{correctResponse}
    <br />
    <table border=1 cellspacing=3 cellpadding=2>
     <tr><td>Item Format:</td><td><b>${formatName}</b></td></tr> 
     ${charDisplay}
     <tr><td>Dev State:</td><td><b>${devStateName}</b></td></tr>
     <tr><td>Difficulty:</td><td><b>${difficultyName}</b></td></tr>
END_HERE

    if ( $item->{hasNotes} ) {
        my $notes = $item->getAllNotes();

        my $notesText = '';

        foreach ( sort { $b cmp $a } keys %{$notes} ) {
            $notesText .=
"$notes->{$_}{lastName}, $notes->{$_}{firstName} ($notes->{$_}{devState}) wrote:\n"
              . $notes->{$_}{notes} . "\n\n";
        }

        $psgi_out .= <<END_HERE;
     <tr>
       <td>Notes:</td><td><textarea rows="6" cols="60" readonly >${notesText}</textarea></td>
     </tr>
END_HERE
    }

    if (%$passages) {
        $psgi_out .= '<tr><td>Linked Passages:</td><td>';

        foreach my $pkey (%$passages) {
            next unless defined $passages->{$pkey}->{name};
            $psgi_out .= '<div><a href="#" onClick="myOpen(\'passageWin\',\''
              . $orcaUrl
              . 'cgi-bin/passageView.pl?passageId='
              . $pkey
              . '\',500,600);">'
              . $passages->{$pkey}->{name}
              . '</a></div>';
        }
        $psgi_out .= '</td></tr>';
    }

    if (%$rubrics) {
        $psgi_out .= '<tr><td>Linked Rubrics:</td><td>';

        foreach my $key (%$rubrics) {
            next unless defined $rubrics->{$key}->{name};
            $psgi_out .= '<div><a href="' 
              . $orcaUrl
              . 'cgi-bin/rubricView.pl?rubricId='
              . $key
              . '" target="_blank">'
              . $rubrics->{$key}->{name}
              . '</a></div>';
        }
        $psgi_out .= '</td></tr>';
    }

    if (%$metafiles) {
        $psgi_out .= <<END_HERE;
	<tr>
	  <td>Metafiles:</td>
		<td><input type="button" value="View Metafiles" onClick="myOpen('itemMetafileWindow','${orcaUrl}cgi-bin/itemMetafiles.pl?itemId=$item->{id}',600,550);"
	  </td>
	</tr>	
END_HERE
    }

    unless ( $item->{sourceDoc} eq '' ) {
        $psgi_out .= <<END_HERE;
     <tr>
       <td>Source Doc:</td><td>$item->{sourceDoc}</td>
     </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
     <tr>
       <td>Writer:</td><td>${itemWriter}</td> 
     </tr>
     <tr>
       <td>Reviewer:</td><td>${itemApprover}</td> 
     </tr>
    </table>
END_HERE

     # this is for role-based commenting on items within standard workflow definition.
     # for current SBAC implementation, we'll use special workflow states to do the committee stuff, so 
     # no need for other comment facilities at this time
     if ( 0 && $user->{rolePermissions}{$RP_COMMENT_ITEM} ) {
	$psgi_out .= qq| 
		<form name="comments">
		<table>
		    <tr>
			<td>
			    Comment:<br/>
			    <textarea name="textarea" cols="30" rows="5"></textarea>
			</td>
		    </tr>
		    <tr>
			<td>
			    <input type="button" class="action_button" name="save_comment" value="Save Comment" />
			</td>
		    </tr>
		</table>
		</form>
	|;
     }

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
