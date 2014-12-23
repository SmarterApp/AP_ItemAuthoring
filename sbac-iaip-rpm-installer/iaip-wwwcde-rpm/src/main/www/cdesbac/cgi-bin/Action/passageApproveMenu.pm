package Action::passageApproveMenu;

use URI::Escape;
use Data::Dumper;
use ItemConstants;
use UrlConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl       = "${orcaUrl}cgi-bin/passageApproveMenu.pl";
  our $noPassagesUrl = "${orcaUrl}noPassagesToReview.html";
  
  our %specialActions = (
      'review_passage'       => '1',
      'review_list'          => '1',
      'select_review_filter' => '1'
  );
  
  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  our $users   = &getUsers($dbh);
  
  $in{itemBankId} = ( keys %$banks )[0] unless exists $in{itemBankId};
  $in{reviewNumber} = 1 unless $in{reviewNumber};

  our $currentWorkGroups = &getUserWorkGroupsForBank($user->{workGroups}, $in{itemBankId});
  if(scalar(keys %{$currentWorkGroups}) && ! $in{workGroupId}) {
    $in{workGroupId} = (keys %{$currentWorkGroups})[0];
  }
  
  our $editors = &getEditors($dbh, $in{itemBankId});
  
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR)
  {
    return [ $q->psgi_header('text/html'), [ print_no_auth() ]];
  }
  
  $in{myAction} = '' unless exists( $in{myAction} );
  
  our $userType = $review_type_map{$user->{reviewType}};
  our $isAdmin = $user->{adminType} ? 1 : 0;
  
  # Get the current workflow for this user
  #warn "Review number = '$in{reviewNumber}', User type = '${userType}',\n";
  our $workflowMap   = defined($q->env->{'cde.cache'}{'workflow.map'}{"$PASSAGE_ACTION_MAP"})
                     ? $q->env->{'cde.cache'}{'workflow.map'}{"$PASSAGE_ACTION_MAP"}
                     : &getActionMap("$PASSAGE_ACTION_MAP");
  our %actionMap     = %{ $workflowMap->{$userType}{ $in{reviewNumber} } };
  our %reviewNumbers = &getWorkListForUserType( $workflowMap, $userType );
  
  our $readDevState;
  
  $in{doCompare} = '0';
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  # Determine the right dev state based on
  # the user type and the review type
  if ( $userType ne '' ) {
  
      $readDevState = $actionMap{state};
      if ( exists $actionMap{compare} ) { $in{doCompare} = '1'; }
  }
  
  # If needed, memorize the last Passage ID
  if ( not( exists $specialActions{ $in{myAction} } )
      and $in{myAction} ne 'recall_last_passage' )
  {
      $in{lastPassageId} = $in{passageId};
  }
  
  # Check each action type and do what is needed
  if ( $in{myAction} eq 'recall_last_passage' ) {
  
      &recallLastPassage();
      $in{myAction} = 'review_passage';
  }
  elsif ( $in{myAction} eq 'quit_review' ) {
    return [ $q->psgi_header('text/html'), [ &quitReview() ]];
  }
  elsif ( $in{myAction} eq 'quit_passage' ) {
    return [ $q->psgi_header('text/html'), [ &quitPassage() ]]; 
  }
  elsif ( not exists( $specialActions{ $in{myAction} } ) ) {
  
    # no special processing if this is a group review
  
    if(exists $actionMap{isGroupReview}) {
  
          $in{myAction} = 'review_list';
  
    } else {
  
      # Set the passage state change based on the %actionMap
      my $states = &getStateFromAction( $in{myAction} );
      if ( exists( $states->{fromState} ) and exists( $states->{toState} ) ) {
          if ( $states->{toState} eq 'last_state' ) {
              $states->{toState} = &getPreviousState( $states->{fromState} )
                || $DS_CONTENT_REVIEW_1;
          }
  
  #print STDERR "Action $in{myAction}, From $states->{fromState}, To $states->{toState}\n";
          &setPassageReviewState( $dbh, $in{passageId}, $states->{fromState},
              $states->{toState}, $user->{id},
              $in{acceptedTimestamp} || 'NOW()' );
          $in{myAction} = 'review_list';
      }
    }
  }
  
  # Select the specified passage for review
  
  if ( $in{myAction} eq 'review_passage' ) {
  
      # Create transaction, get next passage to review, and lock it
      $dbh->{RaiseError} = 1;
      $dbh->{AutoCommit} = 0;
      {
  
        # decide whether to use review lock
  
        my $doReviewLock = 1;
        $doReviewLock = 0 if exists $actionMap{isGroupReview};
  
        # build the sql
  
        my $andReviewLockSql = 'AND (p1.p_review_lock=0 OR p1.p_review_lifetime < ' . $dbh->quote( &get_ts() ) . ')';
        $andReviewLockSql = '' unless $doReviewLock;
  
  
          $sql =
  "SELECT p1.*, (SELECT p2.ps_last_dev_state FROM passage_status AS p2 WHERE p2.p_id=p1.p_id ORDER BY p2.ps_timestamp DESC LIMIT 1) AS last_state FROM passage AS p1 WHERE p1.p_id=$in{passageId} ${andReviewLockSql}"
            . " LIMIT 1";
  
          #warn $sql;
          $sth = $dbh->prepare($sql);
          $sth->execute();
          if ( my $row = $sth->fetchrow_hashref ) {
  
          if( $doReviewLock ) {
  
                $sql =
                      "UPDATE passage SET p_review_lock=1, p_review_lifetime="
                     . $dbh->quote( &get_ts(10800) )
                     . " WHERE p_id=$row->{p_id}";
                $sth = $dbh->prepare($sql);
                $sth->execute();
              }
  
              $in{passageName} = $row->{p_name};
              $in{passageStatus} =
                ( $userType eq 'editor'
                    and defined( $row->{last_state} )
                    and int( $row->{last_state} ) == $DS_CONTENT_REVIEW_1
                  ? 'reject'
                  : '' );
              $in{acceptedTimestamp} = &get_ts();
              $dbh->commit();
          }
          else {
              $dbh->rollback();
              $dbh->{AutoCommit} = 1;
              $in{passageNotFound} = 1;
  
              #warn "Passage Not Found!";
	      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
          }
  
      };
      $dbh->rollback() if $@;
      $dbh->{AutoCommit} = 1;
  
      my %review_type_to_work_type = ( 'graphic_designer' => 1,
                                       'media_designer' => 2,
                       'accessibility_specialist' => 3 );
  
      my $work_supplement_type = $review_type_to_work_type{$userType} || 0;
  
      # Find an associated work supplement id
      $sql = <<SQL;
      SELECT * FROM work_supplemental_info 
        WHERE ib_id=$in{itemBankId} 
          AND wsi_object_type=${OT_PASSAGE}
      AND wsi_object_id=$in{passageId}
      AND wsi_work_type=${work_supplement_type}
SQL
  
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      if ( my $row = $sth->fetchrow_hashref ) {
          $in{supplementalInfoId} = $row->{wsi_id};
      }
 
      return [ $q->psgi_header('text/html'), [ &print_main(\%in) ]];
  }
  elsif ( $in{myAction} eq 'select_review_filter' ) {
    return [ $q->psgi_header('text/html'), [ &print_passage_filter_select(\%in) ]]; 
  }
  elsif ( $in{myAction} eq 'review_list' ) {
  
    # Generate a list of possible passages to review
  
    my @passageList = ();

    # build the query modifiers for users in workgroups
    my $useWorkgroupFilter = 0;

    if(  scalar(keys %{$user->{workGroups}}) 
      && defined($user->{workGroups}{$in{workGroupId}})
      && scalar(keys %{$user->{workGroups}{$in{workGroupId}}{filters}}) ) {
     
      # if in a current work group, a work group must be selected to get items
      if($in{workGroupId} eq '') {
        return [];
      }

      $useWorkgroupFilter = 1;
    }


    $sql =
          "SELECT p1.*, "
        . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=p1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_CONTENT_AREA}) AS content_area,"
        . " (SELECT oc_int_value FROM object_characterization WHERE oc_object_id=p1.p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_GRADE_LEVEL}) AS grade_level,"
        . " (SELECT p2.ps_u_id FROM passage_status AS p2 WHERE p1.p_id=p2.p_id AND p2.ps_last_dev_state=${DS_CONTENT_REVIEW_1} AND p2.ps_new_dev_state=${DS_CONTENT_REVIEW_2} ORDER BY p2.ps_timestamp DESC LIMIT 1) AS cr_user,"
        . " (SELECT p3.ps_u_id FROM passage_status AS p3 WHERE p3.p_id=p1.p_id ORDER BY p3.ps_timestamp DESC LIMIT 1) AS last_user,"
        . " (SELECT p3.ps_last_dev_state FROM passage_status AS p3 WHERE p3.p_id=p1.p_id ORDER BY p3.ps_timestamp DESC LIMIT 1) AS last_state,"
        . " (SELECT p3.ps_timestamp FROM passage_status AS p3 WHERE p3.p_id=p1.p_id ORDER BY p3.ps_timestamp DESC LIMIT 1) AS last_state_date"
        . " FROM /*cde-filter*/ passage AS p1 WHERE /*cde-filter*/ p1.p_dev_state=${readDevState}"
        . ( $userType eq 'editor' ? " AND p1.p_author = $user->{id}" : '' )
        . ( exists( $in{editor} )
            and $in{editor} ne '' ? " AND p1.p_author=$in{editor}" : '' )
        . " AND p1.ib_id = $in{itemBankId}"
        . " AND p1.p_lang = $in{language}"
        . " AND (p1.p_review_lock=0 OR p1.p_review_lifetime < "
        . $dbh->quote( &get_ts() ) . ")"
        . " ORDER BY p1.p_name LIMIT 200";
  
    $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_PASSAGE, 'p1')
      if $useWorkgroupFilter;
    #warn $sql;
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
          #next
          #  if $isContentReviewer
          #      && $in{reviewNumber} eq '2'
          #      && $user->{id} == ( $row->{cr_user} || 0 );
  
          next
            if defined( $row->{content_area} )
                and $in{contentArea} ne ''
                and $in{contentArea} ne $row->{content_area};
          next
            if defined( $row->{grade_level} )
                and $in{gradeLevel} ne ''
                and $in{gradeLevel} ne $row->{grade_level};
  
          my $passage = {};
          $passage->{id}              = $row->{p_id};
          $passage->{name}            = $row->{p_name};
          $passage->{author}          = $row->{p_author};
          $passage->{last_state}      = $row->{last_state};
          $passage->{last_state_date} = $row->{last_state_date};
          $passage->{last_user}       = $row->{last_user};
          $passage->{genre}           = $genres{ $row->{p_genre} };
          $passage->{contentArea} =
            $const[$OC_CONTENT_AREA]->{ $row->{content_area} };
          $passage->{gradeLevel} =
            $const[$OC_GRADE_LEVEL]->{ $row->{grade_level} };
          $passage->{status} = '';
  
          if (    $userType eq 'editor'
              and defined( $row->{last_state} )
              and $row->{last_state} == $DS_CONTENT_REVIEW_1 )
          {
              $passage->{status} = 'reject';
          }
          if (    $userType eq 'content_specialist'
              and -e "${orcaPath}workflow/passage-art-request/$row->{p_id}.html"
              and $row->{last_state} == $DS_DEVELOPMENT )
          {
              $passage->{status} = 'art';
          }
          push( @passageList, $passage );
    }
    return [ $q->psgi_header('text/html'), [ &print_passage_select(\%in, \@passageList) ]];
  }
  else {
  
    # There was an ERROR
    return [ $q->psgi_header('text/plain'), [ 'No Action Selected' ]];
  }
}
### ALL DONE! ###

sub print_passage_select {
  my $psgi_out = '';

    my $params      = shift;
    my $editor      = $params->{editor} || '';
    my $passageList = shift;

    my $onLoad = ( scalar( @{$passageList} ) == 0 ) ? 'loadMenu();' : '';

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Review</title>
        <link rel="stylesheet" href="${orcaUrl}style/text.css" type="text/css" />
        <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
        <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
        <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="JavaScript">

      \$(document).ready(function()
              {
                  \$("#passageTable").tablesorter();
        }
      );

      function doSelectSubmit(id) {
        document.selectPassage.passageId.value = id;
    document.selectPassage.submit();
      }

            function loadMenu() {
           parent.menuFrame.document.location='${orcaUrl}cgi-bin/passageApproveMenu.pl?language=$in{language}&itemBankId=$in{itemBankId}';
            }
    </script>
      <style type="text/css">
        td,th { font-size: 11pt; }
      </style>  
  </head>
  <body onLoad="${onLoad}">
END_HERE

    if ( scalar( @{$passageList} ) == 0 ) {
        $psgi_out .= '<div class="title">No Passages Found matching your search criteria</div>';
    }
    else {

        my $iwHeader =
          ( $userType eq 'editor'
            ? ''
            : '<th>Last User</th><th>Last State</th><th>Date</th>' );

        my $counter = scalar( @{$passageList} );

        $psgi_out .= <<END_HERE;
    <form name="selectPassage" action="${thisUrl}" method="POST" target="menuFrame">
      <input type="hidden" name="myAction" value="review_passage" />
      <input type="hidden" name="language" value="$params->{language}" />
      <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
      <input type="hidden" name="reviewNumber" value="$params->{reviewNumber}" />
      <input type="hidden" name="artType" value="$params->{artType}" />
      <input type="hidden" name="doCompare" value="$params->{doCompare}" />
      <input type="hidden" name="lastPassageId" value="$params->{lastPassageId}" />
            <input type="hidden" name="contentArea" value="$params->{contentArea}" />
            <input type="hidden" name="gradeLevel" value="$params->{gradeLevel}" />
      <input type="hidden" name="editor" value="${editor}" />
      <input type="hidden" name="passageId" value="" />
      
    </form>
    <div class="title">Total = ${counter} passage(s)</div>
    <table id="passageTable" class="tablesorter" border="1" cellspacing="3" cellpadding="3" align="left" width="75%">
          <thead>
      <tr>
        <th>&nbsp;</th><th>Passage ID</th><th>Genre</th><th>Subject</th><th>Grade</th>${iwHeader}<th>Select</th>
      </tr> 
            </thead>
            <tbody>
END_HERE

        foreach my $passage ( @{$passageList} ) {
            my $iwData = (
                $userType eq 'editor' ? '' : '<td>'
                  . (
                    defined( $passage->{last_user} )
                    ? $users->{ $passage->{last_user} }
                    : '&nbsp;'
                  )
                  . '</td><td>'
                  . (
                    defined( $passage->{last_state} )
                    ? $dev_states{ $passage->{last_state} }
                    : '&nbsp;'
                  )
                  . '</td><td>'
                  . ( substr( $passage->{last_state_date}, 0, 10 ) || '&nbsp;' )
                  . '</td>'
            );

            my $status = '';
            if ( $passage->{status} eq 'reject' ) {
                $status =
                    '<img border="0" src="' 
                  . $orcaUrl
                  . 'style/images/bullet_x.gif" />';
            }
            elsif ( $passage->{status} eq 'art' ) {
                $status =
                    '<img border="0" src="' 
                  . $orcaUrl
                  . 'style/images/bullet_a.gif" />';
            }

            $psgi_out .= <<END_HERE;
      <tr>
        <td width="50px">${status}</td>
        <td>$passage->{name}</td>
        <td>$passage->{genre}</td>
    <td>$passage->{contentArea}</td>
    <td>$passage->{gradeLevel}</td>
    ${iwData}
    <td><input type="button" value="Select" onClick="doSelectSubmit($passage->{id});" /></td>
      </tr> 
END_HERE
        }

        $psgi_out .= '</tbody></table>';
    }

    $psgi_out .= <<END_HERE;
  </body>  
</html>
END_HERE

  return $psgi_out;
}

sub print_passage_filter_select {
  my $psgi_out = '';

    my $params = shift;

    my $itemBankName = $banks->{ $params->{itemBankId} }{name};

    my $editor = ( defined $params->{editor} ? $params->{editor} : "" );
    my $editorHtml =
      &hashToSelect( 'editor', $editors, $editor, '', 'null', 'value',
        'font-size:11px;' );

    my $workGroupId = ( defined $params->{workGroupId} ? $params->{workGroupId} : "" );
    my $workGroupHtml = &hashToSelect('workGroupId', $currentWorkGroups,
                                      $workGroupId, '', '', 'value', ); 

    my $contentAreaHtml =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        '', '', 'null:All', '', 'font-size:11px;' );
    my $gradeLevelHtml =
      &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], '', '', 'null:All',
        '', 'font-size:11px;' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Select Passages</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <script language="JavaScript">
    <!--

      function doSave()
      {
    document.passageForm.myAction.value = 'review_list';
        document.passageForm.submit();
    return true;
      }
    //-->
    </script>
  </head>
  <body>
    <div class="title">Select Passage Filter</div>
    <form name="passageForm" action="${thisUrl}" method="post">
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="language" value="$params->{language}" />
      <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
      <input type="hidden" name="reviewNumber" value="$params->{reviewNumber}" />
      <input type="hidden" name="artType" value="$params->{artType}" />
      <input type="hidden" name="doCompare" value="$params->{doCompare}" />
      
          <p>
      <table class="no-style" border="0" cellspacing="2" cellpadding="2">
              <tr>
                  <td><span class="text">Content Area:</span></td>
                    <td>${contentAreaHtml}</td>
                </tr>
              <tr>
                  <td><span class="text">Grade Level:</span></td>
                    <td>${gradeLevelHtml}</td>
                </tr>
              <tr>
                  <td><span class="text">Workgroup:</span></td>
                    <td>${workGroupHtml}</td>
                </tr>
END_HERE

    unless ( $userType eq 'editor' ) {
        $psgi_out .= <<END_HERE;
                <tr>
                  <td><span class="text">Passage Writer:</span></td>
                    <td>${editorHtml}</td>
                </tr>
END_HERE
    }

    $psgi_out .= '</table>';

    $psgi_out .= <<END_HERE;
      </p><p><input type="button" onClick="doSave();" value="Show Available Passages" /></p>
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_welcome {
  my $psgi_out = '';

    my $params = shift;

    my $msg = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;'>$params->{message}</div>"
        : "" );

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $defaultBank =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : "5" );
    my $itemBankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $defaultBank, '', '' );

    #my $languageDisplay = &hashToSelect('language',\%languages,'1','','');

    my $defaultRN =
      ( defined $params->{reviewNumber} ? $params->{reviewNumber} : '1' );
    my $reviewNumberDisplay =
      &hashToSelect( 'reviewNumber', \%reviewNumbers, $defaultRN, '', '' );

    my $onLoad = (
        defined( $in{passageNotFound} )
        ? 'onLoad="showNoPassageMessage();"'
        : '' );

    my $spaceWidth = ( $userType eq 'editor' ? 40 : 15 );

    my $actionValue = 'select_review_filter';
    my $frameTarget = 'rightFrame';

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Review</title>
    <script language="JavaScript">
    <!-- 
      function doReviewSubmit() {
        document.form1.myAction.value = '${actionValue}';
    document.form1.target = '${frameTarget}';
    document.form1.submit();
    return true;
      }

      function showNoPassageMessage() {
        parent.rightFrame.document.location='${noPassagesUrl}';
    return true;
      }
    //--> 
    </script>
    <style type="text/css">
      input.button { font-size:12px; } 
      td.grey { background-color: #f0f0f0; }
      select { font-size:12px; }
    </style>
  </head>
  <body ${onLoad}>
    <form name="form1" action="${thisUrl}" method="POST">
      <input type="hidden" name="myAction" value="" />
      
      <input type="hidden" name="doCompare" value="$params->{doCompare}" />
      <input type="hidden" name="language" value="1" />
    <table border="0" cellspacing="0" cellpadding="3" align="left" class="no-style">
      <tr>
END_HERE

    if ($isAdmin) {
        $psgi_out .= <<END_HERE;
        <td><input class="button" type="button" 
                           onClick="parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/itemPassageManage.pl';" value="Manage Passages" style="width:150px;"/></td>
    <td style="width:${spaceWidth}px;"></td>
END_HERE
    }

    $psgi_out .= <<END_HERE;
        <td class="grey"><span class="text">Program:</span></td>
        <td class="grey">${itemBankDisplay}</td>
    <td class="grey" style="width:${spaceWidth}px;"></td>
        <td class="grey"><span class="text">Review:</span></td>
        <td class="grey">${reviewNumberDisplay}</td>
    <td class="grey" style="width:${spaceWidth}px;"></td>
    <td class="grey"><input type="button" class="button" value="Start Review" onClick="doReviewSubmit();">
        <td style="width:${spaceWidth}px"></td>
        <td style="width:${spaceWidth}px"></td>
                <td><input class="button" type="button" 
                           onClick="parent.document.location.href='${orcaUrl}cgi-bin/itemApprove.pl';" value="Main Menu" style="width:100px;" /></td>
        <td style="width:${spaceWidth}px"></td>
      </tr> 
    </table>
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_main {
  my $psgi_out = '';

    my $params = shift;

    my $itemBankId     = $params->{itemBankId};
    my $artType        = $params->{artType};
    my $language       = $params->{language};
    my $passageId      = $params->{passageId};
    my $editor         = $params->{editor} || '';
    my $lastPassageId  = $params->{lastPassageId} || '';
    my $passageName    = $params->{passageName};
    my $safeExternalId = uri_escape( $passageName, "^A-Za-z0-9" );
    my $myAction       = $params->{myAction};
    my $reviewNumber   = $params->{reviewNumber};
    my $supplementalInfoId = $params->{supplementalInfoId} || 0;
    my $furl           = uri_escape(
        "${orcaUrl}cgi-bin/passageSingleReview.pl?passageId=${passageId}");

    my $loadPassageJS = "function loadPassage() {\n";
    my $supplementalInfoJS = "";
    my $jsCode = '';

    if ( $userType eq 'graphic_designer' || $userType eq 'media_designer' || $userType eq 'accessibility_specialist' ) {

        if($userType eq 'accessibility_specialist') {
          $loadPassageJS .= <<END_HERE;
          parent.rightFrame.document.location.href = '${javaUrl}/AccessibilityTagging.jsf?passage=${passageId}';
END_HERE

        } else {
          $loadPassageJS .= <<END_HERE;
          parent.rightFrame.document.location='${orcaUrl}cgi-bin/passageSingleReview.pl?passageId=${passageId}';
END_HERE
        }

        if($supplementalInfoId) {

          $jsCode = <<END_HERE;
          window.open('${orcaUrl}cgi-bin/supplementalInfoView.pl?supplementalInfoId=${supplementalInfoId}','_blank','toolbar=yes,copyhistory=no,resizable=yes,scrollbars=yes,width=600,height=600');
END_HERE
        } else {
          $jsCode = <<END_HERE;
      alert('Supplemental Information not provided for this item.');
END_HERE
        }

	$loadPassageJS .= $jsCode;
	$supplementalInfoJS .= $jsCode;
    }
    elsif ( $params->{passageStatus} eq 'reject' ) {
        $loadPassageJS .= <<END_HERE;
      parent.rightFrame.document.location='${orcaUrl}cgi-bin/passageSingleReview.pl?passageId=${passageId}';
      window.open('${orcaUrl}cgi-bin/passageRejectionReport.pl?myAction=get&rejectState=1&itemBankId=$in{itemBankId}&passageId=${passageId}','_blank','toolbar=yes,copyhistory=no,resizable=yes,scrollbars=yes,width=500,height=500');
END_HERE
    }
    elsif ( exists $actionMap{isGroupReview} ) {
        $loadPassageJS .= <<END_HERE;
    parent.rightFrame.document.location='${orcaUrl}cgi-bin/passageGroupReview.pl?passageId=${passageId}&doCommentView=1&commentViewState=1';
END_HERE
    }
    elsif ( exists $actionMap{isGroupReviewLead} ) {
        $loadPassageJS .= <<END_HERE;
    parent.rightFrame.document.location='${orcaUrl}cgi-bin/passageGroupReview.pl?passageId=${passageId}&doCommentView=1&commentViewState=2';
END_HERE
    }
    else {
        $loadPassageJS .= <<END_HERE;
    parent.rightFrame.document.location='${orcaUrl}cgi-bin/passageSingleReview.pl?passageId=${passageId}';
END_HERE
    }

    $loadPassageJS .= "}\n";

    my $frameTarget = 'rightFrame';

    if ( $userType eq 'editor' ) {

        # Set the menu back to option select
        my $submitAction = <<END_HERE;
    document.form1.submit();
    document.form1.target = 'menuFrame';
    document.form1.myAction.value = '';
    document.form1.submit();
END_HERE
    }

    my $compareParam = ( $params->{doCompare} eq '1' ? '&doCompare' : '' );

    my $rejectFunction = '';

    if ( exists $actionMap{reject} ) {
        $rejectFunction = <<END_HERE;
      function doRejectSubmit() {
        document.form1.myAction.value = '$actionMap{reject}{action}';
          document.form1.submit();
          parent.menuFrame.document.location='${orcaUrl}cgi-bin/passageApproveMenu.pl?language=$in{language}&itemBankId=$in{itemBankId}';
          return true;
      }
END_HERE
    }

    if ( $userType eq 'content_specialist'
        and ( $reviewNumber eq '1' ) )
    {

        my $rejectState = 1;
        #if ( $reviewNumber eq '4' ) { $rejectState = 9; }

        if ( exists $actionMap{reject} ) {
            $rejectFunction = <<END_HERE;
      function doRejectSubmit() {
        document.form1.myAction.value = '$actionMap{reject}{action}';
          window.open('${orcaUrl}cgi-bin/passageRejectionReport.pl?itemBankId=$in{itemBankId}&passageId=${passageId}&myAction=put&rejectState=${rejectState}&submitForm=yes&userId=$user->{id}','_blank','width=600,height=500,directories=no,toolbar=no,status=no,copyhistory=no,resizable=yes,scrollbars=yes');
          return true;
      }
END_HERE
        }
    }

    my %review_with_edit_map = map { $_ => 1 } @review_with_edit;

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage Review</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <script language="JavaScript">
    <!-- 

      ${rejectFunction}
     
      function doAcceptSubmit() {
        document.form1.myAction.value = '$actionMap{accept}{action}';
          document.form1.submit();
          parent.menuFrame.document.location='${orcaUrl}cgi-bin/passageApproveMenu.pl?language=$in{language}&itemBankId=$in{itemBankId}';
          return true;
      }

END_HERE

    my %status_functions = (
        'accept'   => 'Accept',
        'reject'   => 'Reject',
        'expedite' => 'Expedite',
        'branch'   => 'Branch',
        'new_art'  => 'NewArt',
        'fix_art'  => 'EditArt',
        'new_media'  => 'NewMedia',
        'fix_media'  => 'EditMedia',
    'new_accessibility' => 'NewAccessibility',
    'fix_accessibility' => 'EditAccessibility' 
    );

    foreach(qw/expedite branch new_art fix_art new_media fix_media new_accessibility fix_accessibility/) {

      if ( exists $actionMap{$_} ) {

        $psgi_out .= <<END_HERE;

    function do$status_functions{$_}Submit() {
          document.form1.myAction.value = '$actionMap{$_}{action}';
      document.form1.submit();
      parent.menuFrame.document.location='${orcaUrl}cgi-bin/passageApproveMenu.pl?language=$in{language}&itemBankId=$in{itemBankId}';
      return true;
        }

END_HERE
      } 
    }


    $psgi_out .= <<END_HERE;

      function doEditSubmit() {
        document.getElementById('action_accept').style.display = 'none';
        parent.rightFrame.document.location='${orcaUrl}cgi-bin/itemPassageCreate.pl?itemBankId=${itemBankId}&pname=${safeExternalId}&myAction=edit${compareParam}&furl=${furl}';
    return true;
      }
      
      function doQuitSubmit() {
        document.form1.myAction.value = 'quit_review';
    document.form1.submit();
    return true;
      }
      
            function doQuitPassageSubmit() {
        document.form1.myAction.value = 'quit_passage';
    document.form1.submit();
    return true;
      }
      
      function doRecallSubmit() {
        document.form1.target = 'menuFrame';
        document.form1.myAction.value = 'recall_last_passage';
          document.form1.submit();
          return true;
      }

      function openSupplementalInfo() {

        if(document.form1.supplementalInfo.selectedIndex == 0) {
      return;
    }

        document.supplementalInfoForm.workType.value = document.form1.supplementalInfo.selectedIndex;
    document.supplementalInfoForm.submit();
      }

            function showMessage() {
              if('$params->{message}' != '') {
                  alert('$params->{message}');
                }
            }

	    function viewSupplementalInfo() {
	      ${supplementalInfoJS}
	    }
      
      ${loadPassageJS}
    //--> 
    </script>
        <style type="text/css">
          input.button {font-size:12px;}
        </style>    
  </head>
  <body onLoad="loadPassage(); showMessage();">
    <form name="supplementalInfoForm" action="${orcaUrl}cgi-bin/supplementalInfoCreate.pl" method="POST" target="_blank">
      
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="objectId" value="${passageId}" />
      <input type="hidden" name="objectType" value="${OT_PASSAGE}" />
      <input type="hidden" name="workType" value="" />
    </form>
    <form name="form1" action="${thisUrl}" method="POST" target="${frameTarget}">
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="passageId" value="${passageId}" />
      <input type="hidden" name="lastPassageId" value="${lastPassageId}" />
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="language" value="${language}" />
      <input type="hidden" name="editor" value="${editor}" />
      <input type="hidden" name="reviewNumber" value="${reviewNumber}" />
      <input type="hidden" name="artType" value="${artType}" />
      
      <input type="hidden" name="doCompare" value="$params->{doCompare}" />
            <input type="hidden" name="contentArea" value="$params->{contentArea}" />
            <input type="hidden" name="gradeLevel" value="$params->{gradeLevel}" />
      <input type="hidden" name="acceptedTimestamp" value="$params->{acceptedTimestamp}" />
    <table width="98%" border="0" cellspacing="2" cellpadding="2" class="no-style">
      <tr>
END_HERE

    # Build the toolbar

    my $toolbar =
'<td style="background-color:#e0e0e0;" valign="middle"><span style="vertical-align:middle;"><b>Set Status:</b></span>&nbsp;&nbsp;';

    foreach (qw/accept reject expedite branch new_art fix_art new_media fix_media new_accessibility fix_accessibility/) {
        next unless exists $actionMap{$_};

        $toolbar .= <<END_HERE;
          <span id="action_$_"><a href="#" onClick="do$status_functions{$_}Submit();"><img border="0" src="${orcaUrl}style/images/workflow/$_.gif" title="$actionMap{$_}{label}" /></a>&nbsp;&nbsp;</span>
END_HERE
    }

    $toolbar .= '</td><td>&nbsp;&nbsp;&nbsp;&nbsp;</td>';

    $psgi_out .= $toolbar;

    if($userType eq 'content_specialist' || $userType eq 'editor') {
    $psgi_out .= <<END_HERE;
        <td>&nbsp; 
        <select name="supplementalInfo" onChange="openSupplementalInfo();">
          <option value="">Supplemental Info</option>
          <option value="1">Art</option>
          <option value="2">Media</option>
          <option value="3">Accessibility</option>
        </select></td>
END_HERE
    }

    if($userType eq 'graphic_designer' || $userType eq 'media_designer' || $userType eq 'accessibility_specialist') {
      $psgi_out .= <<END_HERE;
	<td><input type="button" class="action_button" value="Supplemental Info" onClick="viewSupplementalInfo();" /></td>
END_HERE
    }

    if( exists $review_with_edit_map{$userType} ) {

      $psgi_out .= <<END_HERE;
    <td><input type="button" class="button" value="Edit Passage" onClick="doEditSubmit();" /></td>
END_HERE
    }

    $psgi_out .= <<END_HERE;
        <td><input type="button" class="button" style="width:100px;" value="Quit Passage" onClick="doQuitPassageSubmit();" /></td>
        <td><input type="button" class="button" style="width:100px;" value="Quit Review" onClick="doQuitSubmit();" /></td>
        <td><input type="button" class="button" style="width:100px;" value="Recall Passage" onClick="doRecallSubmit();" /></td>
END_HERE

    $psgi_out .= <<END_HERE;
      </tr> 
    </table>
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}

# Return a hash with 'fromState' and 'toState' keys based on the user action
sub getStateFromAction {
    my $actionId = shift;
    return {} if $userType eq '';
    my $mapSection = $workflowMap->{$userType};
    foreach my $stageKey ( keys %{$mapSection} ) {
        foreach my $actionKey ( keys %{ $mapSection->{$stageKey} } ) {
            next unless ref( $mapSection->{$stageKey}{$actionKey} );
            if ( $mapSection->{$stageKey}{$actionKey}{action} eq $actionId ) {
                return {
                    'fromState' => $mapSection->{$stageKey}{state},
                    'toState'   => $mapSection->{$stageKey}{$actionKey}{state}
                };
            }
        }
    }

    warn 
"Passage Workflow: Unable to find action for actionId = '${actionId}' and userType = '${userType}'\n";
    return {};
}

# Return the last dev state this passage was in
sub getPreviousState {
    my $currentState = shift;
    $sql =
        "SELECT ps_last_dev_state FROM passage_status WHERE p_id=$in{passageId}"
      . " AND ps_new_dev_state=${currentState} ORDER BY ps_timestamp DESC LIMIT 1";
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        return $row->{ps_last_dev_state};
    }
    else {
        return 0;
    }
}

sub recallLastPassage {

    # 1) Release the lock on the current passage
    # 2) Use the passage with ID = 'lastPassageId'

    unless(exists $actionMap{isGroupReview}) {

      $sql = "UPDATE passage SET p_review_lock=0 WHERE p_id=$in{passageId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    if($in{lastPassageId}) {

      $sql = "SELECT p_name FROM passage WHERE p_id=$in{lastPassageId} AND p_review_lock=0";
      $sth = $dbh->prepare($sql);
      $sth->execute();

      if ( my $row = $sth->fetchrow_hashref ) {
        $in{passageId} = $in{lastPassageId};
      } else {
        $in{message} =  'Your Previous Passage has already been locked by another user.';
      }
    } else {
        $in{message} =  'Your Previous Passage is not found.';
    }

}

sub quitReview {

    # 1) Release the lock on this passage

    unless(exists $actionMap{isGroupReview}) {

      $sql = "UPDATE passage SET p_review_lock=0 WHERE p_id=$in{passageId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    # 2) Go back to beginning
    return <<END_HERE;
  <html>
    <head>
      <script language="JavaScript">
      <!--
        function closeTheWindow() {
      parent.document.location='${orcaUrl}cgi-bin/passageApprove.pl?language=$in{language}&itemBankId=$in{itemBankId}';
    }
      //-->
      </script>
    </head>
    <body onLoad="closeTheWindow();">
    </body>
  </html>
END_HERE
}

sub quitPassage {

    # 1) Release the lock on this passage

    unless(exists $actionMap{isGroupReview}) {

      $sql = "UPDATE passage SET p_review_lock=0 WHERE p_id=$in{passageId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    # 2) Go back to passage selection
    delete $in{myAction};

    my $urlParamsString = join( '&',
        map { $_ . '=' . uri_escape( $in{$_}, "^A-Za-z0-9" ) } keys %in );

    return <<END_HERE;
  <html>
    <head>
      <script language="JavaScript">
      <!--
        function closeTheWindow() {
      parent.menuFrame.document.location='${orcaUrl}cgi-bin/passageApproveMenu.pl?myAction=&${urlParamsString}';              
      parent.rightFrame.document.location='${orcaUrl}cgi-bin/passageApproveMenu.pl?myAction=review_list&${urlParamsString}';
    }
      //-->
      </script>
    </head>
    <body onLoad="closeTheWindow();">
    </body>
  </html>
END_HERE
}

sub getUserWorkGroupsForBank {

  my $wg = shift;
  my $itemBankId = shift;

  my %out = map { $_ => $wg->{$_}{name} } grep { $wg->{$_}{bank} == $itemBankId } keys %$wg;
  return \%out;
}
1;
