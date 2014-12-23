package Action::itemGroupReview;

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
  
  our $item = new Item( $dbh, $in{itemId} );
  
  our $commentViewState = $in{commentViewState} || 0;
  
  # this will hold a list of all comments, if used
  our %comment_list = ();
  
  # add a comment
  
  if($in{myAction} eq 'addComment') {
  
    &addItemComment($dbh, $in{itemId}, $user->{id}, $commentViewState, 
                    $item->{devState}, $in{itemRating}, $in{commentText});
  
    $in{message} = 'Comment Updated.';  
  }
  
  # look for an existing comment from this user, in case we've already commented on it
  
  $sql = sprintf('SELECT * FROM item_comment WHERE i_id=%d AND u_id=%d AND ic_dev_state=%d AND ic_type=%d',
                 $in{itemId},
  	       $user->{id},
  	       $item->{devState},
  	       $commentViewState);
  $sth = $dbh->prepare($sql);
  $sth->execute();
  if(my $row=$sth->fetchrow_hashref) {
  
    $in{itemRating} = $row->{ic_rating};
    $in{commentText} = $row->{ic_comment};
  }
  
  # if this is a lead, then also assemble the list of comments already made
  
  if($commentViewState == 2) {
  
    $sql = <<SQL;
    SELECT ic.*, u.u_first_name, u.u_last_name 
      FROM item_comment AS ic, user AS u
      WHERE ic.i_id=$in{itemId} 
        AND ic.ic_dev_state=$item->{devState} 
        AND ic.ic_type=1
        AND ic.u_id=u.u_id
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    while(my $row = $sth->fetchrow_hashref) {
  
      my $key = $row->{ic_id};
  
      $comment_list{$key}{userId} = $row->{u_id};
      $comment_list{$key}{userName} = $row->{u_last_name} . ', ' . $row->{u_first_name}; 
      $comment_list{$key}{rating} = $item_rating{$row->{ic_rating}}; 
      $comment_list{$key}{comment} = $row->{ic_comment}; 
      $comment_list{$key}{timestamp} = $row->{ic_timestamp}; 
  
    }
    $sth->finish;
  }

  return [ $q->psgi_header('text/html'), [ &print_item(\%in) ]];
}
### ALL DONE! ###

sub print_item {
  my $psgi_out = '';

    my $params = shift;

    my $c   = $item->getDisplayContent();
    my $gle = $item->getGLE();

    my $documentReadyFunction = $c->{documentReadyFunction};

    my $formatName       = $item_formats{ $item->{format} }              || '';
    my $difficultyName = $difficulty_levels{ $item->{difficulty} } || '';
    my $itemApprover   = $item->getApprover();
    my $itemWriter     = $item->{authorName}                       || '';
    my $devStateName   = $dev_states{ $item->{devState} };

    my $doCommentView = $params->{doCommentView} || 0;
    my $commentViewState = $params->{commentViewState} || 0;

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

    my $displayRatingHtml = &hashToSelect( 'itemRating', \%item_rating, $in{itemRating} || 0 );

    #my $mediaAssets = &getMediaAssetAttributes($dbh, $item->{id});
    #if (scalar(@{$mediaAssets})>0) {
    #   $documentReadyFunction .= '$("#noMediaMessage").hide();';
    #} 

    if($commentViewState == 2) {

      $documentReadyFunction .= "\$(\"#commentTable\").tablesorter();\n";
    }

    my $msg = ($in{message} eq '') ? '' : '<p style="color:blue;">' . $in{message} . '</p>';

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html>
  <head>
    <title>Item Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css">
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
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

      function doCommentSubmit() {

        document.itemForm.myAction.value = 'addComment';
        document.itemForm.submit();
      }


  </script>
  </head>
  <body>
      <form name="itemForm" action="itemGroupReview.pl" method="POST">
        <input type="hidden" name="myAction" value="" />
	<input type="hidden" name="itemId" value="$in{itemId}" />
	
	${msg}
      <br />
      <p>Item:&nbsp;&nbsp;<b>$item->{name}</b>&nbsp;&nbsp;&lt;$item->{bankName}&gt;<br />
      Description:&nbsp;&nbsp;$item->{description}</p>
END_HERE

    if ( $gleName ne '' ) {
        $psgi_out .= <<END_HERE;
     <table class="no-style" border="1" cellspacing="3" cellpadding="3" width="455">
       <tr><th align="center">GLE ${gleName}</th></tr>
       <tr><td>${gleText}</td></tr>
     </table>
     <br />
END_HERE
    }

    if($doCommentView) {

        $psgi_out .= <<END_HERE;
	<input type="hidden" name="doCommentView" value="${doCommentView}" />
	<input type="hidden" name="commentViewState" value="${commentViewState}" />
     <table border="1" cellspacing="2" cellpadding="2">
       <tr>
         <td>Comment</td>
         <td><textarea name="commentText" rows="4" cols="50">$in{commentText}</textarea></td>
       </tr>
       <tr>
         <td>Rating</td>
	 <td>${displayRatingHtml}</td>
       </tr>
       <tr>
         <td colspan="2"><input type="button" value="Add/Update Comment" onClick="doCommentSubmit();" /></td>
       </tr>
     </table>
    </form>
     <br />
END_HERE

      if($commentViewState == 2) {

        $psgi_out .= <<END_HERE;
	<p>Reviewer Comments:</p>
        <table id="commentTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2">
          <thead>
            <tr>
              <th width="15%">Rating</th>
              <th width="45%">Comment</th>
              <th width="15%">User</th>
              <th width="15%">Time</th>
            </tr>
          </thead>
          <tbody>
END_HERE

        foreach my $key (sort { $comment_list{$b}{timestamp} cmp $comment_list{$a}{timestamp} }
                         keys %comment_list) {

          my $data = $comment_list{$key};

          $psgi_out .= <<END_HERE;
          <tr>
            <td>$data->{rating}</td>
            <td>$data->{comment}</td>
            <td>$data->{userName}</td>
            <td>$data->{timestamp}</td>
          </tr>
END_HERE
        }
      
        $psgi_out .= '</tbody></table><br />';
      }
    }

    $psgi_out .= <<END_HERE;
    <p><a href="${orcaUrl}cgi-bin/cde.pl?action=displayPublicationHistory&item_id=$in{itemId}&instance_name=${instance_name}" target="_blank">View Item Publication History</a></p>
    <br />
    $c->{itemBody}
END_HERE

    #$psgi_out .= "<br />".&getMediaTableHtml($mediaAssets);

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

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
