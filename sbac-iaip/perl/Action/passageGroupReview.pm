package Action::passageGroupReview;

use ItemConstants;
use Passage;
use PassageMediaTable qw(View_Mode);
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  our $this_url = "${orcaUrl}cgi-bin/passageGroupReview.pl";
  
  our $sth;
  our $sql;
  
  our $userType = $review_type_map{$user->{reviewType}};
  our $isAdmin = $user->{adminType} ? 1 : 0;
  
  our $psg = new Passage( $dbh, $in{passageId} );
  
  our $commentViewState = $in{commentViewState} || 0;
  
  # this will hold a list of all comments, if used
  our %comment_list = ();
  
  # add a comment
  
  if($in{myAction} eq 'addComment') {
  
    &addPassageComment($dbh, $in{passageId}, $user->{id}, $commentViewState, 
                    $psg->{devState}, $in{passageRating}, $in{commentText});
  
    $in{message} = 'Comment Updated.';  
  }
  
  # look for an existing comment from this user, in case we've already commented on it
  
  $sql = sprintf('SELECT * FROM passage_comment WHERE p_id=%d AND u_id=%d AND pc_dev_state=%d AND pc_type=%d',
                 $in{passageId},
  	       $user->{id},
  	       $psg->{devState},
  	       $commentViewState);
  $sth = $dbh->prepare($sql);
  $sth->execute();
  if(my $row=$sth->fetchrow_hashref) {
  
    $in{passageRating} = $row->{pc_rating};
    $in{commentText} = $row->{pc_comment};
  }
  $sth->finish;
  
  # if this is a lead, then also assemble the list of comments already made
  
  if($commentViewState == 2) {
  
    $sql = <<SQL;
    SELECT pc.*, ad.ad_first_name, ad.ad_last_name 
      FROM passage_comment AS pc, user AS u
      WHERE pc.p_id=$in{passageId} 
        AND pc.pc_dev_state=$psg->{devState} 
        AND pc.pc_type=1
        AND pc.u_id=u.u_id
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    while(my $row = $sth->fetchrow_hashref) {
  
      my $key = $row->{ic_id};
  
      $comment_list{$key}{userId} = $row->{u_id};
      $comment_list{$key}{userName} = $row->{u_last_name} . ', ' . $row->{u_first_name}; 
      $comment_list{$key}{rating} = $item_rating{$row->{pc_rating}}; 
      $comment_list{$key}{comment} = $row->{pc_comment}; 
      $comment_list{$key}{timestamp} = $row->{pc_timestamp}; 
  
    }
    $sth->finish;
  }

  return [ $q->psgi_header('text/html'), [ &print_passage(\%in) ]];
}
### ALL DONE! ###

sub print_passage {
  my $psgi_out = '';

    my $params = shift;

    my $content  = $psg->{content};

    my $documentReadyFunction = '';

    my $passageWriter     = $psg->{authorName}                       || '';
    my $devStateName   = $dev_states{ $psg->{devState} };

    my $doCommentView = $params->{doCommentView} || 0;
    my $commentViewState = $params->{commentViewState} || 0;

    my $charDisplay = <<HTML;
    <tr>
      <td>Content Area:</td>
      <td>$const[$OC_CONTENT_AREA]->{$psg->{contentArea}}</td>
    </tr>
    <tr>
      <td>Grade Level:</td>
      <td>$const[$OC_GRADE_LEVEL]->{$psg->{gradeLevel}}</td>
    </tr>
HTML


    my $displayRatingHtml = &hashToSelect( 'passageRating', \%item_rating, $in{passageRating} || 0 );

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

        document.passageForm.myAction.value = 'addComment';
        document.passageForm.submit();
      }


  </script>
  </head>
  <body>
      <form name="passageForm" action="${this_url}" method="POST">
        <input type="hidden" name="myAction" value="" />
	<input type="hidden" name="passageId" value="$in{passageId}" />
	
	${msg}
      <br />
      <div class="title">Passage:&nbsp;&nbsp;<b>$psg->{name}</b>&nbsp;&nbsp;&lt;$psg->{bankName}&gt;</div>
      Description:&nbsp;&nbsp;$psg->{summary}<br /><br />
END_HERE


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
    <table class="no-style" border="1" cellpadding="2" cellspacing="2">
      <tbody>
       <tr>
         <td valign="top"> 
         ${content}
         </td>  
       </tr>
      </tbody>
    </table>
END_HERE


    $psgi_out .= <<END_HERE;
    <br />
    <br />
    <table border=1 cellspacing=3 cellpadding=2>
     ${charDisplay}
     <tr><td>Dev State:</td><td><b>${devStateName}</b></td></tr>
     <tr>
       <td>Author:</td><td>${passageWriter}</td> 
     </tr>
    </table>
  </body>
</html>
END_HERE

  return $psgi_out;
}
1;
