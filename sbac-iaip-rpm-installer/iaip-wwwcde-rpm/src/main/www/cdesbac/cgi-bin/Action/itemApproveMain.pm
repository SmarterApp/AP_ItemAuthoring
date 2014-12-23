package Action::itemApproveMain;

use URI::Escape;
use ItemConstants;
use UrlConstants;
use Session;
use CGI::Cookie;
use Data::Dumper;
use Time::HiRes;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $debug = 1;
  our $start_time;

  our $thisUrl    = "${orcaUrl}cgi-bin/itemApproveMain.pl";
  our $menuUrl    = "${orcaUrl}cgi-bin/itemApproveMenu.pl";
  our $noItemsUrl = "${orcaUrl}noItemsToReview.html";
  
  our $HD_SS_CONTENT = 6;
  
  our %specialActions = (
      'review_item'          => '1',
      'review_list'          => '1',
      'select_review_filter' => '1'
  );
  
  our $sth;
  our $sql;
  
  our $user = Session::getUser($q->env, $dbh);
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  our $users   = &getUsers($dbh);
  
  $in{itemBankId} = ( keys %$banks )[0] unless $in{itemBankId};
  $in{reviewNumber} = 1 unless $in{reviewNumber};

  our $currentWorkGroups = &getUserWorkGroupsForBank($user->{workGroups}, $in{itemBankId});
  if(scalar(keys %{$currentWorkGroups}) && ! $in{workGroupId}) {
    $in{workGroupId} = (keys %{$currentWorkGroups})[0];
  }
  
  our $editors = &getEditors($dbh, $in{itemBankId});
  
  our $workflowMap   = defined($q->env->{'cde.cache'}{'workflow.map'}{"$ITEM_ACTION_MAP"})
                     ? $q->env->{'cde.cache'}{'workflow.map'}{"$ITEM_ACTION_MAP"}
                     : &getActionMap("$ITEM_ACTION_MAP");
  our $userType = $review_type_map{$user->{reviewType}};
  
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and exists ($workflowMap->{$userType}) )
  {
     return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ]; 
  }
  
  $in{myAction} = 'select_review_filter' unless defined( $in{myAction} );
  
  our $isAdmin = $user->{adminType} ? 1 : 0;
  
  # Get the current workflow for this user
  #warn "Review number = '$in{reviewNumber}', User type = '${userType}',\n";
  our %actionMap     = %{ $workflowMap->{$userType}{ $in{reviewNumber} } };
  our %reviewNumbers = &getWorkListForUserType( $workflowMap, $userType );
  
  our %review_fields = (
      name => {
          label => 'Item ID',
          value => 'name',
          size  => '12'
      },
      standard => {
          label => 'Hierarchy',
          value => 'gle',
          size  => '14'
      },
      pub_status => {
          label => 'Publication Status',
          value => 'publication_status',
          size  => '12'
      },
      item_format => {
          label => 'Item Format',
          value => 'item_format',
          size  => '8'
      },
      writer => {
          label => 'Item Writer',
          value => 'item_writer',
          size  => '9'
      },
      lastUser => {
          label => 'Last User',
          value => 'last_user',
          size  => '8'
      },
      lastSaveUser => {
          label => 'Hold',
          value => 'last_save_user',
          size  => '7'
      },
      lastState => {
          label => 'Last State',
          value => 'last_state',
          size  => '9'
      },
      lastDate => {
          label => 'Date',
          value => 'last_state_date',
          size  => '7'
      },
      imsID => {
          label => 'IMS ID',
          value => 'ims_id'
      },
      description => {
          label => 'Description',
          value => 'description',
          size  => '10'
      },
  );
  
  our %user_review_fields;
  foreach( keys %$banks ) {
      $user_review_fields{$_} = {
          	'editor' => [ 
  			'name', 'standard', 'description' 
  		],
          	'content_review' => [ 
  			'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate', 
          	],
          	'content_specialist' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'copy_editor' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'graphic_designer' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'media_designer' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'accessibility_specialist' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'committee_reviewer' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'data_reviewer' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'qc_presentation' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'data_manager' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'psychometrician' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
          	'committee_facilitator' => [
              		'name',     'standard', 'description', 'item_format', 'pub_status', 'writer',
              		'lastUser', 'lastState', 'lastDate',
          	],
      };
  }
  
  
  our $readDevState;
  
  $in{doCompare}      = '0';
  $in{doCompareState} = '0';
  $in{itemNotesTag}   = '0';
  
  if ( $in{myAction} eq '' ) {
   return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
  }
  
  # Determine the right dev state based on
  # the user type and the review type
  warn "[userType:$userType]";
  if ( $userType ne '' ) {
  
      $readDevState = $actionMap{state};
      if ( exists $actionMap{compare} ) { $in{doCompare} = '1'; }
      if ( exists $actionMap{compareState} ) {
          $in{doCompareState} = $actionMap{compareState};
      }
      if ( exists $actionMap{itemNotesTag} ) {
          $in{itemNotesTag} = $actionMap{itemNotesTag};
      }
  }
  warn "[doCompare:$in{doCompare}]";
  
  # If needed, memorize the last Item ID
  if ( not( exists $specialActions{ $in{myAction} } )
      and $in{myAction} ne 'recall_last_item' )
  {
      $in{lastItemId} = $in{itemId};
  }
  
  # Check each action type and do what is needed
  if ( $in{myAction} eq 'recall_last_item' ) {
  
      &recallLastItem();
      $in{myAction} = 'review_item';
  }
  elsif ( $in{myAction} eq 'quit_review' ) {
 
    return [ $q->psgi_header('text/html'), [ &quitReview() ] ];
  }
  elsif ( $in{myAction} eq 'quit_item' ) {
  
    return [ $q->psgi_header('text/html'), [ &quitItem() ] ];
  }
  elsif ( not exists( $specialActions{ $in{myAction} } ) ) {
  
    # no special processing if this is a group review
  
    if(exists $actionMap{isGroupReview}) {
  
          $in{myAction} = 'select_review_filter';
  
    } else {
  
      # Set the item state change based on the %actionMap
      my $states = &getStateFromAction( $in{myAction} );
      if ( exists( $states->{fromState} ) and exists( $states->{toState} ) ) {
  
          if ( $states->{toState} eq 'last_state' ) {
              $states->{toState} = &getPreviousState( $states->{fromState} )
                || $DS_CONTENT_REVIEW_1;
          }
  
  #warn "Action $in{myAction}, From $states->{fromState}, To $states->{toState}\n";
          &setItemReviewState( $dbh, $in{itemId}, $states->{fromState},
              $states->{toState}, $user->{id},
              $in{acceptedTimestamp} || 'NOW()' );
          if ( exists $in{minorEdit} ) {
              if ( $in{minorEdit} ) {
  
                  # Set the 'minor edit' flag
                  $sql =
  "INSERT INTO item_characterization SET i_id=$in{itemId}, ic_type=${OC_MINOR_EDIT}, ic_value=1";
              }
              else {
  
                  # Clear the 'minor edit' flag
                  $sql =
  "DELETE FROM item_characterization WHERE i_id=$in{itemId} AND ic_type=${OC_MINOR_EDIT}";
              }
              $sth = $dbh->prepare($sql);
              $sth->execute();
              $sth->finish;
          }
  
          $in{myAction} = 'select_review_filter';
      }
  
    }
  }
  
  # Select the specified item for review
  
  if ( $in{myAction} eq 'review_item' ) {
  
      # Create transaction, get next item to review, and lock it
      $dbh->{RaiseError} = 1;
      $dbh->{AutoCommit} = 0;
      {
       
        # decide whether to use review lock
  
        my $doReviewLock = 1;
        $doReviewLock = 0 if exists $actionMap{isGroupReview};
  
        # build the sql
  
        my $andReviewLockSql = 'AND (i_review_lock=0 OR i_review_lifetime < ' . $dbh->quote( &get_ts() ) . ')';
        $andReviewLockSql = '' unless $doReviewLock;
  
          $sql =
  "SELECT t1.*, (SELECT t2.is_last_dev_state FROM item_status AS t2 WHERE t2.i_id=t1.i_id ORDER BY t2.is_timestamp DESC LIMIT 1) AS last_state FROM item AS t1 WHERE i_id=$in{itemId} ${andReviewLockSql}"
            . " LIMIT 1";
  
          #warn $sql;
          $sth = $dbh->prepare($sql);
          $sth->execute();
          if ( my $row = $sth->fetchrow_hashref ) {
  
  	    if( $doReviewLock ) {
  
                $sql =  "UPDATE item SET i_review_lock=1, i_review_lifetime="
                     . $dbh->quote( &get_ts(10800) )
                     . " WHERE i_id=$row->{i_id}";
                $sth = $dbh->prepare($sql);
                $sth->execute();
              }
  
              $in{itemExternalId} = $row->{i_external_id};
              $in{itemStatus} =
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

              $in{itemLocked} = 1;
              #warn "Item Not Found!";

	      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
          }
  
      };
      $dbh->rollback() if $@;
      $dbh->{AutoCommit} = 1;
  
      # Find an associated rubric to bind to the 'edit rubric' function
      $sql = <<SQL;
      SELECT * FROM scoring_rubric 
        WHERE sr_id=(SELECT ic_value FROM item_characterization WHERE i_id=$in{itemId} AND ic_type=${OC_RUBRIC} LIMIT 1)
SQL
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      #warn $sql;
      if ( my $row = $sth->fetchrow_hashref ) {
          $in{assignedRubricName} = $row->{sr_name};
          $in{assignedRubricBank} = $row->{ib_id};
      }
      $sth->finish;
  
      my %review_type_to_work_type = ( 'graphic_designer' => 1,
                                       'media_designer' => 2,
  				     'accessibility_specialist' => 3 );
  
      my $work_supplement_type = $review_type_to_work_type{$userType} || 0;
  
      # Find an associated work supplement id
      $sql = <<SQL;
      SELECT * FROM work_supplemental_info 
        WHERE ib_id=$in{itemBankId} 
          AND wsi_object_type=${OT_ITEM}
  	AND wsi_object_id=$in{itemId}
  	AND wsi_work_type=${work_supplement_type}
SQL
  
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      if ( my $row = $sth->fetchrow_hashref ) {
          $in{supplementalInfoId} = $row->{wsi_id};
      }
 
      return [ $q->psgi_header('text/html'), [ &print_main(\%in) ] ];
  }
  elsif ( $in{myAction} eq 'select_review_filter' ) {
  
      $start_time = [Time::HiRes::gettimeofday()];
      &selectReviewFilter( $in{itemBankId} );
  
      my $itemList = &getItemsToReview();

      my $diff = Time::HiRes::tv_interval($start_time);
      warn "Item review list loaded in $diff\n";
 
      return [ $q->psgi_header('text/html'), [ &print_item_filter_select(\%in, $itemList) ] ];
  }
  else {
  
    # There was an ERROR
    return [ $q->psgi_header('text/plain'), [ 'No Action Selected' ] ];
  }
}
### ALL DONE! ###

sub print_item_filter_select {
  my $psgi_out = '';

    my $params   = shift;
    my $itemList = shift;

    my $hId          = $params->{hierarchyId};
    my $hdIdRoot     = $params->{hdId0};
    my $hLabel       = $params->{label0};
    my $itemBankName = $banks->{ $params->{itemBankId} }{name};
    my $level        = $params->{level};

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $itemBankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $params->{itemBankId},
        'resetFilter(); return true;', '', 'value'  );

    #my $languageDisplay = &hashToSelect('language',\%languages,'1','','');

    my $reviewNumberDisplay =
      &hashToSelect( 'reviewNumber', \%reviewNumbers, $params->{reviewNumber},
        'updateFilter(this.value);', '', '', 'width:150px;' );

    my $selectHtml = "";

    for ( my $i = 1 ; $i <= $params->{level} ; $i++ ) {
        $selectHtml .=
            $params->{ 'label' . $params->{"type${i}"} }
          . ':&nbsp;&nbsp;'
          . '<select style="font-size:11px;" name="hdId'
          . $i . '"'
          . ' onChange="setGLEFilterLevel('
          . $i
          . '); return true;">'
          . '<option value="">'
          . ( $i > 2 ? 'All' : '' )
          . '</option>';

        my $model = $params->{"model${i}"};
        my $pos   = $params->{"pos${i}"};

        foreach my $key ( sort { $pos->{$a} <=> $pos->{$b} } keys %$pos ) {
            $selectHtml .=
                '<option value="' 
              . $key . '"'
              . ( defined( $params->{"hdId${i}"} )
                  && $params->{"hdId${i}"} eq $key ? ' SELECTED' : '' )
              . '>'
              . $model->{$key}
              . '</option>';
        }

        $selectHtml .= '</select>&nbsp;&nbsp;&nbsp;';
    }

    my $hiddenHtml = "";

    foreach my $key ( grep { /^label/ } keys %$params ) {
        $hiddenHtml .=
            '<input type="hidden" name="' 
          . $key
          . '" value="'
          . $params->{$key} . '" />';
    }

    my $editor = ( defined $params->{editor} ? $params->{editor} : "" );
    my $editorHtml =
      &hashToSelect( 'editor', $editors, $editor, 'updateFilter(this.value);', 'null:All',
        'value', );

    my $passageId =
      ( defined $params->{passageId} ? $params->{passageId} : "" );
    my $passageHtml =
      &hashToSelect( 'passageId',
        &getPassageList( $dbh, $params->{itemBankId} ),
        $passageId, 'updateFilter(this.value);', 'null', 'value', );

    my $workGroupId = ( defined $params->{workGroupId} ? $params->{workGroupId} : "" );
    my $workGroupHtml = &hashToSelect('workGroupId', $currentWorkGroups,
                                      $workGroupId, 'updateFilter(this.value);', '', 'value', ); 

    my $projects = &getProjects( $dbh, $in{itemBankId} );
    my $projectId =
      ( defined $params->{projectId} ? $params->{projectId} : "" );
    my $projectHtml =
      &hashToSelect( 'projectId', $projects, $projectId, 'updateFilter(this.value);',
        'null:All', 'value', );

    my $publicationStatusDisplay =
      &hashToSelect( 'publicationStatus', \%publication_status,
        ( defined $params->{publicationStatus} ? $params->{publicationStatus} : "" ), 
	'updateFilter(this.value);', '', '', ' ' );

    my $itemFormatDisplay =
      &hashToSelect( 'itemFormat', \%item_formats,
        ( defined $params->{itemFormat} ? $params->{itemFormat} : "" ), 
	'updateFilter(this.value);', '', 'value', ' ' );

    my $reviewDisplay = <<END_HERE;
        <td class="grey"><span class="text">Review:</span>&nbsp;&nbsp;${reviewNumberDisplay}</td>
END_HERE

    $in{language} ||= '';
    $params->{$_} ||= ''
      for (
        qw( level reviewNumber artType doCompare doCompareState itemNotesTag lastItemId )
      );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title> Select Items</title>
	<link rel="stylesheet" href="${orcaUrl}style/text.css" type="text/css" />
	<link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
	<script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
	<script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="JavaScript">

      \$(document).ready(function()
			  {
				  \$("#itemTable").tablesorter();
        }
      );

      function setGLEFilterLevel(level)
      {
        document.itemSelect.level.value = level;
	      document.itemSelect.myAction.value = 'select_review_filter';
	      document.itemSelect.submit();
        return true; 
      }

      function updateFilter(v) {

        if(document.itemSelect.itemBankId.selectedIndex == 0) {
	  alert('Please select a Program.');
	  return false;
        }

        if(document.itemSelect.reviewNumber.selectedIndex == 0) {
	  alert('Please select a Review state.');
	  return false;
        }

	if(v == '') return;
	document.getElementById('progress_spinner').innerHTML = '<img src="/common/images/spinner.gif" />';
       document.itemSelect.myAction.value = 'select_review_filter';
        document.itemSelect.submit();
				return true;
     }

      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
	return true; 
      }

			function resetFilter() {

                          if(document.itemSelect.itemBankId.selectedIndex == 0) {
			    return false;
                          }


			   document.itemSelect.passageId.selectedIndex = 0;
				 document.itemSelect.level.value = '1';
				 document.itemSelect.hdId1.value = '0';
				 document.itemSelect.label1.value = '';
	       document.itemSelect.myAction.value = 'select_review_filter';
				 document.itemSelect.submit();
	       return true;
			}

      function doSelectSubmit(id) {
			  document.itemSelect.target = 'menuFrame';
				document.itemSelect.myAction.value = 'review_item';
        document.itemSelect.itemId.value = id;
	      document.itemSelect.submit();
      }

			function loadMenu() {
	       parent.menuFrame.document.location='${thisUrl}?language=$in{language}&itemBankId=$in{itemBankId}';
			}

			function loadCompareStatus() {
			   var compareStatus = getCookie('comparisonModeStatus');
				 if(compareStatus == 'disable') {
				   document.itemSelect.disableCompare.checked = true;
				 }
			}

			function updateCompareStatus() {
			  if(document.itemSelect.disableCompare.checked) {
				  setCookie('comparisonModeStatus','disable');
        } else {
				  setCookie('comparisonModeStatus','enable');
        }
			}

      function setCookie(name,value) {
			  document.cookie = name + "=" + value + "; path=/"; 
			}

			function getCookie(name) {
			  var nameEq = name + "=";
				var ca = document.cookie.split(';');
				for(var i=0; i < ca.length; i++) {
				  var c = ca[i];
					while (c.charAt(0) == ' ')
					  c = c.substring(1, c.length);
					if(c.indexOf(nameEq) == 0)
					  return c.substring(nameEq.length,c.length);
				}
				return '';
			}

    </script>
    <style type="text/css">

      table.standards {
          background-color: #cfcfcf; 
      }

      input.button { font-size:11px; } 

      td.grey { background-color: #f0f0f0; }

	    td,th { font-size: 11px; }

      select { font-size:11px; }

    </style>
  </head>
  <body onLoad="loadCompareStatus();">
    <form name="itemSelect" action="${thisUrl}" method="GET">
      <input type="hidden" name="hierarchyId" value="${hId}" />
      <input type="hidden" name="hdId0" value="${hdIdRoot}" />
      <input type="hidden" name="level" value="$params->{level}" />
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="language" value="1" />
      <!-- this is part of a select box already

      <input type="hidden" name="reviewNumber" value="$params->{reviewNumber}" />
      -->
      <input type="hidden" name="artType" value="$params->{artType}" />
      <input type="hidden" name="doCompare" value="$params->{doCompare}" />
      <input type="hidden" name="doCompareState" value="$params->{doCompareState}" />
      <input type="hidden" name="itemNotesTag" value="$params->{itemNotesTag}" />
      <input type="hidden" name="lastItemId" value="$params->{lastItemId}" />
      <input type="hidden" name="itemId" value="" />
      
      ${hiddenHtml}
    <table style="border:1px solid black;" cellpadding="3" cellspacing="3">
		  <tr><td>
			  <table class="no-style" border="0" cellpadding="5" cellspacing="5">
			    <tr>
					  <td colspan="3"><span class="title">Select Item Filters</span></td>
			    </tr>
			    <tr>
				    <td class="grey">Program:&nbsp;&nbsp;${itemBankDisplay}</td>
					  ${reviewDisplay}	
          </tr>
			<tr><td>
        ${selectHtml}
			</td>
			      <td>Passage:&nbsp;&nbsp;${passageHtml}</td>
			    <td>Workgroup:&nbsp;&nbsp;${workGroupHtml}</td>
			</tr>
			<tr>
			    <td>Item Format:&nbsp;&nbsp;$itemFormatDisplay</td>
			    <td>Publication Status:&nbsp;&nbsp;$publicationStatusDisplay</td>
END_HERE
    if ( $userType eq 'editor' ) {
        $psgi_out .= <<END_HERE;
				  <td>&nbsp;<input type="hidden" name="editor" value="${editor}" /></td>
END_HERE
    }
    else {
        $psgi_out .= <<END_HERE;
				  <td>Item Writer:&nbsp;&nbsp;${editorHtml}</td>
END_HERE
    }
    $psgi_out .= <<END_HERE;
			</tr>
			<tr>
            <td><input class="button" type="button" style="width:100px;" onClick="updateFilter(1);" value="Refresh List" /><span id="progress_spinner"></span></td>
            <td colspan="2"><input class="button" type="button" style="width:130px;" onClick="myOpen('historyWin','${orcaUrl}cgi-bin/userWorkflowHistory.pl?itemBankId=$params->{itemBankId}',600,550);" value="Show Queue History" /></td>
			</tr>
		</table>
		</table>
END_HERE

    # Print the list of available items

    if ( scalar( @{$itemList} ) == 0 ) {
        $psgi_out .= '<h3>No Items Found matching your search criteria</h3>';
    }
    else {

        my $counter = scalar( @{$itemList} );

        $psgi_out .= <<END_HERE;
  <br />
    <span style="font-size:13px;font-weight:bold;margin-right:30px;">Total = ${counter} item(s)</span>
END_HERE

        if ( $params->{passageId} ne '' ) {
            $psgi_out .= <<END_HERE;
	 <p><a href="#" onClick="window.open('${orcaUrl}cgi-bin/passageView.pl?passageId=$params->{passageId}','passagewin','width=640,height=500,directories=no,toolbar=no,location=no,resizable=yes,scrollbars=yes');">View Passage</a></p>
END_HERE
        }

        my $header = '<td width="1%" border=0" bgcolor="#e6EEEE" align="center">Select</td><td width="2%" bgcolor="#e6EEEE" align="center">Flags</td>';
        $header .= '<th'
          . (
            exists $review_fields{$_}{size}
            ? ' width="' . $review_fields{$_}{size} . '%" '
            : '' )
          . '>'
          . $review_fields{$_}{label} . '</th>'
          foreach @{ $user_review_fields{ $params->{itemBankId} }{$userType} };

        $psgi_out .= <<END_HERE;
	  <span><input type="checkbox" name="disableCompare" onClick="updateCompareStatus();" />&nbsp;&nbsp;Disable Comparison Mode</span>
    <br />
    <table id="itemTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2" align="left">
		  <thead>
        <tr>
          ${header}
        </tr>	
      </thead>
			<tbody>
END_HERE

        foreach
          my $item ( sort { $a->{gle_sort_order} cmp $b->{gle_sort_order} }
            @{$itemList} )
        {

            $item->{flags} = '';

	    foreach (grep { exists $item->{status}{$_} } keys %review_flags) {
              $item->{flags} .= '<span style="color:' . $review_flags{$_}{color} . ';font-weight:bold;">'
	                      . $review_flags{$_}{tag} . '</span>&nbsp;';
	    }

            my $row =
'<td align="center"><input type="button" value="Select" style="font-size:11px;" onClick="doSelectSubmit('
              . $item->{id}
              . ');" /></td>' . '<td>'
              . $item->{flags} . '</td>';

            $row .= '<td><span style="font-size:11px;">'
              . (
                (
                        !$item->{ $review_fields{$_}{value} }
                      || $item->{ $review_fields{$_}{value} } eq ''
                ) ? '&nbsp;' : $item->{ $review_fields{$_}{value} }
              )
              . '</span></td>'
              foreach
              @{ $user_review_fields{ $params->{itemBankId} }{$userType} };

            $psgi_out .= "<tr>${row}</tr>";
        }

        $psgi_out .= '</tbody></table>';
    }

    $psgi_out .= <<END_HERE;
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

    my $reviewNumberDisplay =
      &hashToSelect( 'reviewNumber', \%reviewNumbers, $params->{reviewNumber},
        '', '' );

    my $onLoad =
      ( defined( $in{itemNotFound} ) ? 'onLoad="showNoItemMessage();"' : '' );

    if($in{itemLocked}) {
      $onLoad = 'onLoad="showItemLockedMessage();"';
    }

    my $spaceWidth = ( $userType eq 'editor' ? 20 : 8 );

    my $actionValue = 'select_review_filter';
    my $frameTarget = 'rightFrame';

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Review</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <script language="JavaScript">
    <!-- 
      function doReviewSubmit() {
        document.form1.myAction.value = '${actionValue}';
	document.form1.target = '${frameTarget}';
	document.form1.submit();
	return true;
      }

      function showNoItemMessage() {
        parent.rightFrame.document.location='${noItemsUrl}';
	return true;
      }

      function showItemLockedMessage() {
        alert('Item is locked by another user.');
	doReviewSubmit();
      }
    //--> 
    </script>
    <style type="text/css">
      input.button { font-size:12px; } 
      td.grey { background-color: #cfcfcf; }
      select { font-size:12px; }
    </style>
  </head>
  <body ${onLoad}>
    <form name="form1" action="${thisUrl}" method="GET">
      <input type="hidden" name="myAction" value="" />
      
      <input type="hidden" name="doCompare" value="$params->{doCompare}" />
      <input type="hidden" name="doCompareState" value="$params->{doCompareState}" />
      <input type="hidden" name="itemNotesTag" value="$params->{itemNotesTag}" />
      <input type="hidden" name="language" value="1" />
    <table border="0" cellspacing="0" cellpadding="3" align="left" class="no-style">
      <tr>
END_HERE

    if ($isAdmin) {
        $psgi_out .= <<END_HERE;
        <td><input class="button" type="button" onClick="parent.menuFrame.document.location.href='${orcaUrl}cgi-bin/itemAdminMenu.pl';" value="Item Admin" style="width:80px;"/></td>
	<td style="width:${spaceWidth}px;"></td>
END_HERE
    }

    $psgi_out .= <<END_HERE;
        <td class="grey"><span class="text">Bank:</span></td>
        <td class="grey">${itemBankDisplay}</td>
	<td class="grey" style="width:${spaceWidth}px;"></td>
        <td class="grey"><span class="text">Review:</span></td>
        <td class="grey">${reviewNumberDisplay}</td>
	<td class="grey" style="width:${spaceWidth}px;"></td>
	<td class="grey"><input type="button" class="button" value="Review Items" onClick="doReviewSubmit();">
        <td style="width:${spaceWidth}px"></td>
	<td><input type="button" class="button" value="Review Passages" onClick="parent.document.location.href='${orcaUrl}cgi-bin/passageApprove.pl';" style="width:90px;" /></td>
        <td style="width:${spaceWidth}px"></td>
	<td><input type="button" class="button" value="Review Passage/Item Sets" onClick="parent.document.location.href='${orcaUrl}cgi-bin/pisetApprove.pl';" style="width:90px;" /></td>
        <td style="width:${spaceWidth}px"></td>
END_HERE

    if ( $userType ne 'editor' || $isAdmin ) {
        $psgi_out .= <<END_HERE;
	<td><input type="button" class="button" value="Report" onClick="window.open('${orcaUrl}cgi-bin/itemReport.pl','_blank','directories=no,toolbar=no,status=no,scrollbars=yes,width=780,height=570,left=50,top=50');" /></td>
        <td style="width:${spaceWidth}px"></td>
	<td><input type="button" class="button" value="Print Item" onClick="window.open('${orcaUrl}cgi-bin/itemPrintList.pl','_blank','directories=no,toolbar=yes,status=no,resizable=yes,scrollbars=yes,left=50,top=50,width=600,height=500');" /></td>
        <td style="width:${spaceWidth}px"></td>
	<td><input type="button" class="button" value="Passage Report" onClick="window.open('${orcaUrl}cgi-bin/passageReport.pl','_blank','directories=no,toolbar=no,status=no,scrollbars=yes,width=720,height=570,left=50,top=50');" style="width:90px;" /></td>
        <td style="width:${spaceWidth}px"></td>
END_HERE
    }

    $psgi_out .= <<END_HERE;
	      <td><input type="button" class="button" onClick="window.open('${orcaUrl}cgi-bin/itemView.pl','_blank','directories=no,toolbar=no,status=no,scrollbars=yes,width=460,height=510,left=50,top=50');" value="View Item" /></td>
        <td style="width:${spaceWidth}px"></td>
	      <td><input type="button" class="button" onClick="window.parent.rightFrame.document.location.href='${orcaUrl}cgi-bin/itemRubricCreate.pl';" value="Create Rubric" style="width:90px;"/></td>
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
    my $itemId         = $params->{itemId};
    my $editor         = $params->{editor} || '';
    my $lastItemId     = $params->{lastItemId} || '';
    my $itemExternalId = $params->{itemExternalId};
    my $safeExternalId = uri_escape($itemExternalId);
    my $myAction       = $params->{myAction};
    my $reviewNumber   = $params->{reviewNumber};
    my $supplementalInfoId = $params->{supplementalInfoId} || 0;
    my $furl           = uri_escape(
"${orcaUrl}cgi-bin/itemSingleReview.pl?itemId=${itemId}"
    );

    my $hiddenHtml = "";
    foreach my $key ( keys %$params ) {
        next
          if $key !~ /^hdId/
              && $key !~ /^label/
              && $key !~ /^projectId/
              && $key ne 'level';
        $hiddenHtml .=
            '<input type="hidden" name="' 
          . $key
          . '" value="'
          . $params->{$key} . '" />';
    }

    my $loadItemJS = "function loadItem() {\n";
    my $supplementalInfoJS = "";
    my $jsCode = '';

    if ( $userType eq 'graphic_designer' || $userType eq 'media_designer' || $userType eq 'accessibility_specialist' ) {

        if($userType eq 'accessibility_specialist') {
          $loadItemJS .= <<END_HERE;
          parent.rightFrame.document.location.href = '${javaUrl}AccessibilityTagging.jsf?item=${itemId}';
END_HERE

        } else {
          $loadItemJS .= <<END_HERE;
          parent.rightFrame.document.location='${orcaUrl}cgi-bin/itemSingleReview.pl?itemId=${itemId}';
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

        $loadItemJS .= $jsCode;
        $supplementalInfoJS .= $jsCode; 
    }
    elsif ( $params->{itemStatus} eq 'reject' ) {
        $loadItemJS .= <<END_HERE;
      parent.rightFrame.document.location='${orcaUrl}cgi-bin/itemSingleReview.pl?itemId=${itemId}';
      window.open('${orcaUrl}cgi-bin/itemRejectionReport.pl?myAction=get&rejectState=1&itemBankId=$in{itemBankId}&itemId=${itemId}','_blank','toolbar=yes,copyhistory=no,resizable=yes,scrollbars=yes,width=500,height=500');
END_HERE
    }
    elsif ( exists $actionMap{isGroupReview} ) {
        $loadItemJS .= <<END_HERE;
    parent.rightFrame.document.location='${orcaUrl}cgi-bin/itemGroupReview.pl?itemId=${itemId}&doCommentView=1&commentViewState=1';
END_HERE
    }
    elsif ( exists $actionMap{isGroupReviewLead} ) {
        $loadItemJS .= <<END_HERE;
    parent.rightFrame.document.location='${orcaUrl}cgi-bin/itemGroupReview.pl?itemId=${itemId}&doCommentView=1&commentViewState=2';
END_HERE
    }
    else {
        $loadItemJS .= <<END_HERE;
    parent.rightFrame.document.location='${orcaUrl}cgi-bin/itemSingleReview.pl?itemId=${itemId}';
END_HERE
    }

    $loadItemJS .= "}\n";

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

    my $editRubricUrl =
"${orcaUrl}cgi-bin/itemRubricCreate.pl?itemBankId=${itemBankId}&furl=${furl}";
    if ( exists $params->{assignedRubricName} ) {
        my $escapedName =
          uri_escape( $params->{assignedRubricName}, '^A-Za-z0-9' );
        $editRubricUrl =
"${orcaUrl}cgi-bin/itemRubricCreate.pl?myAction=edit&itemBankId=$params->{assignedRubricBank}&rname=${escapedName}&furl=${furl}";
    }

    my $compareParam =
      ( $params->{doCompare} eq '1'
        ? '&doCompare&doCompareState=' . $params->{doCompareState}
        : '' );
    my $notesTagParam =
      ( $params->{itemNotesTag} eq '0'
        ? ''
        : '&itemNotesTag=' . $params->{itemNotesTag} );

    my $rejectFunction = '';

    if ( exists $actionMap{reject} ) {

        $rejectFunction = <<END_HERE;
      function doRejectSubmit() {
        document.form1.myAction.value = '$actionMap{reject}{action}';
	      document.form1.submit();
	      parent.menuFrame.document.location='${menuUrl}?language=$in{language}&itemBankId=$in{itemBankId}';
	      return true;
      }
END_HERE
    }

    if ( $userType eq 'content_specialist'
        and ( $reviewNumber eq '1' ) )
    {
        my $rejectState = 1;

        if ( exists $actionMap{reject} ) {

            $rejectFunction = <<END_HERE;
      function doRejectSubmit() {
        document.form1.myAction.value = '$actionMap{reject}{action}';
	      window.open('${orcaUrl}cgi-bin/itemRejectionReport.pl?itemBankId=$in{itemBankId}&itemId=${itemId}&myAction=put&rejectState=${rejectState}&submitForm=yes&userId=$user->{id}','_blank','width=600,height=500,directories=no,toolbar=no,status=no,copyhistory=no,resizable=yes,scrollbars=yes');
	      return true;
      }
END_HERE
        }
    }

    my %review_with_edit_map = map { $_ => 1 } @review_with_edit;

    my $minorEditJs = '';

    if(exists $review_with_edit_map{$userType}) {

      $minorEditJs = <<END_HERE;
      if(parent.rightFrame.document.form1.minorEdit.checked == true) {
	  document.form1.minorEdit.value = '1';
      }
END_HERE
    }

    $psgi_out .= <<END_HERE;
<html>
  <head>
    <title>Item Review</title>
    <script language="JavaScript">
    <!-- 

      ${rejectFunction}
     
      function doAcceptSubmit() {
 
        ${minorEditJs} 

        document.form1.myAction.value = '$actionMap{accept}{action}';
	      document.form1.submit();
	     parent.menuFrame.document.location='${orcaUrl}cgi-bin/itemApproveMenu.pl?language=$in{language}&itemBankId=$in{itemBankId}';
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
	  parent.menuFrame.document.location='${orcaUrl}cgi-bin/itemApproveMenu.pl?language=$in{language}&itemBankId=$in{itemBankId}';
	  return true;
        }

END_HERE
      } 
    }

    $psgi_out .= <<END_HERE;
      function doEditSubmit() {
        document.getElementById('action_accept').style.display = 'none';
        parent.rightFrame.document.location='${itemCreateUrl}?itemBankId=${itemBankId}&externalId=${safeExternalId}&myAction=edit${compareParam}${notesTagParam}&furl=${furl}';
	return true;
      }
      
			function doEditRubricSubmit() {
        document.getElementById('action_accept').style.display = 'none';
        parent.rightFrame.document.location='${editRubricUrl}';
	return true;
      }

      function doQuitSubmit() {
        document.form1.myAction.value = 'quit_review';
	document.form1.submit();
	return true;
      }
      
			function doQuitItemSubmit() {
        document.form1.myAction.value = 'quit_item';
	document.form1.submit();
	return true;
      }
      
      function doRecallSubmit() {
        document.form1.target = 'menuFrame';
        document.form1.myAction.value = 'recall_last_item';
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
      
      ${loadItemJS}
    //--> 
    </script>
		<style type="text/css">
		  input.button {font-size:12px;}

			td {
			     vertical-align:middle;
			     margin-right:10px;
				}
		</style>	
  </head>
  <body onLoad="loadItem(); showMessage();">
    <form name="supplementalInfoForm" action="${orcaUrl}cgi-bin/supplementalInfoCreate.pl" method="POST" target="_blank">
      
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="objectId" value="${itemId}" />
      <input type="hidden" name="objectType" value="${OT_ITEM}" />
      <input type="hidden" name="workType" value="" />
    </form>
    <form name="form1" action="${thisUrl}" method="GET" target="${frameTarget}">
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="itemId" value="${itemId}" />
      <input type="hidden" name="lastItemId" value="${lastItemId}" />
      <input type="hidden" name="itemBankId" value="${itemBankId}" />
      <input type="hidden" name="language" value="${language}" />
      <input type="hidden" name="editor" value="${editor}" />
      <input type="hidden" name="reviewNumber" value="${reviewNumber}" />
      <input type="hidden" name="artType" value="${artType}" />
      
      <input type="hidden" name="doCompare" value="$params->{doCompare}" />
      <input type="hidden" name="doCompareState" value="$params->{doCompareState}" />
      <input type="hidden" name="itemNotesTag" value="$params->{itemNotesTag}" />
      <input type="hidden" name="passageId" value="$params->{passageId}" />
      <input type="hidden" name="acceptedTimestamp" value="$params->{acceptedTimestamp}" />
			<input type="hidden" name="minorEdit" value="0" />
			${hiddenHtml}
    <table border="0" cellspacing="2" cellpadding="2">
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
	<td><input type="button" class="action_button" value="Edit Item" onClick="doEditSubmit();" /></td>
	<td><input type="button" class="action_button" value="Edit Rubric" onClick="doEditRubricSubmit();" /></td>
END_HERE
    }


    $psgi_out .= <<END_HERE;
        <td><input type="button" class="action_button" value="Quit Item" onClick="doQuitItemSubmit();" /></td>
        <td><input type="button" class="action_button" value="Quit Review" onClick="doQuitSubmit();" /></td>
        <td><input type="button" class="action_button" value="Recall Item" onClick="doRecallSubmit();" /></td>
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
            if ( $mapSection->{$stageKey}{$actionKey}{'action'} eq $actionId ) {
                return {
                    'fromState' => $mapSection->{$stageKey}{state},
                    'toState'   => $mapSection->{$stageKey}{$actionKey}{state}
                };
            }
        }
    }

    warn 
"Item Workflow: Unable to find action for actionId = '${actionId}' and userType = '${userType}'\n";
    return {};
}

# Return the last dev state this item was in
sub getPreviousState {
    my $currentState = shift;
    $sql = "SELECT is_last_dev_state FROM item_status WHERE i_id=$in{itemId}"
      . " AND is_new_dev_state=${currentState} AND is_last_dev_state != ${currentState} ORDER BY is_timestamp DESC LIMIT 1";
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        return $row->{is_last_dev_state};
    }
    else {
        return 0;
    }
}

sub recallLastItem {

    # 1) Release the lock on the current item
    # 2) Use the item with ID = 'lastItemId'

    unless(exists $actionMap{isGroupReview}) {

      $sql = "UPDATE item SET i_review_lock=0 WHERE i_id=$in{itemId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    if($in{lastItemId}) {
      $sql = "SELECT i_external_id FROM item WHERE i_id=$in{lastItemId} AND i_review_lock=0";
      $sth = $dbh->prepare($sql);
      $sth->execute();

      if ( my $row = $sth->fetchrow_hashref ) {
        $in{itemId} = $in{lastItemId};
      } else {
        $in{message} =  'Your Previous Item has already been locked by another user.';
      }
    } else {
        $in{message} =  'Your Previous Item has not been found.';
    }
}

sub quitReview {

    # 1) Release the lock on this item

    unless(exists $actionMap{isGroupReview}) {

      $sql = "UPDATE item SET i_review_lock=0 WHERE i_id=$in{itemId}";
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
	  parent.document.location='${orcaUrl}cgi-bin/itemApprove.pl?language=$in{language}&itemBankId=$in{itemBankId}';
	}
      //-->
      </script>
    </head>
    <body onLoad="closeTheWindow();">
    </body>
  </html>
END_HERE
}

sub quitItem {

    # 1) Release the lock on this item

    unless(exists $actionMap{isGroupReview}) {

      $sql = "UPDATE item SET i_review_lock=0 WHERE i_id=$in{itemId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    # 2) Go back to item selection

    delete $in{myAction};

    my $urlParamsString = join( '&',
        map { $_ . '=' . uri_escape( $in{$_}, "^A-Za-z0-9" ) } keys %in );

    return <<END_HERE;
  <html>
    <head>
      <script language="JavaScript">
      <!--
        function closeTheWindow() {
	        parent.menuFrame.document.location='${menuUrl}?myAction=&${urlParamsString}';			  
	        parent.rightFrame.document.location='${thisUrl}?myAction=select_review_filter&${urlParamsString}';
	      }
      //-->
      </script>
    </head>
    <body onLoad="closeTheWindow();">
    </body>
  </html>
END_HERE
}

sub selectReviewFilter {
    my $itemBankId = shift;

    my %hierarchy_for_bank;  
    my $sql2 = "SELECT * FROM standard_hierarchy WHERE sh_id = ?";
    my $sth2 = $dbh->prepare($sql2);
    foreach my $ib_id ( keys %$banks ) {
        $sth2->execute( $banks->{$ib_id}->{sh_id} );
        if ( my $row = $sth2->fetchrow_hashref ) {
             $hierarchy_for_bank{$ib_id} = {
                name => $row->{sh_external_id},
                shId => $row->{sh_id},
                hdId => $row->{hd_id},
             };
        }
    }

    $in{hierarchyId} = $hierarchy_for_bank{$itemBankId}{shId};
    $in{hdId0}       = $hierarchy_for_bank{$itemBankId}{hdId};
    $in{label0}      = $hierarchy_for_bank{$itemBankId}{name};
    $in{level}       = 0 unless exists $in{level};

    $in{text} = {};    #Holds the text descriptions
    for ( my $i = 0 ; $i <= $in{level} ; $i++ ) {
        next unless $in{"hdId${i}"};

        # Build one drop-down list ( 1 step of the hierarchy )
        my $iplus = $i + 1;
        my $sql   = "SELECT * FROM hierarchy_definition WHERE hd_parent_id="
          . $in{"hdId${i}"};
        $sth = $dbh->prepare($sql);
        $sth->execute()
          || warn( "Failed Query:" 
              . $sql
              . "\nError is "
              . $dbh->err . ","
              . $dbh->errstr );

        $in{"model${iplus}"} = {};    # hd_id to hd_value map
        $in{"pos${iplus}"}   = {};    # hd_id to hd_posn_in_parent map
        while ( my $row = $sth->fetchrow_hashref ) {
            $in{"model${iplus}"}->{ $row->{hd_id} } = $row->{hd_value};
            $in{"pos${iplus}"}->{ $row->{hd_id} }   = $row->{hd_posn_in_parent};
            $in{"type${iplus}"}                     = $row->{hd_type};

            if ( $row->{hd_std_desc} ) {
                $in{text}->{ $row->{hd_id} } = $row->{hd_std_desc};
                $in{textType} = $row->{hd_type};
            }

        }
    }

    unless ( defined( $in{label1} ) && $in{label1} ne '' ) {

        # Save all labels for later use
        my $sql = "SELECT * FROM qualifier_label WHERE sh_id='$in{hierarchyId}'";
        $sth = $dbh->prepare($sql);
        $sth->execute()
          || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
        while ( my $row = $sth->fetchrow_hashref ) {
            $in{"label$row->{ql_type}"} = $row->{ql_label};
        }
    }
}

sub getItemsToReview {

    # Generate a list of possible items to review

    # Do a standards-based search
    my $searchHdId    = 0;
    my $searchHdLevel = 0;
    for ( my $i = 1 ; $i <= $in{level} ; $i++ ) {
        last unless exists $in{"hdId${i}"} && $in{"hdId${i}"} ne '';
        $searchHdLevel = $i;
    }
    $searchHdId = $in{"hdId${searchHdLevel}"} if $searchHdLevel;

    $in{"hdId$in{level}"} ||= '';
    $in{"type$in{level}"} ||= -1;
    $in{level} = $in{level} + 1
      unless $in{"hdId$in{level}"} eq '' || $in{"type$in{level}"} == $HD_SS_CONTENT;

    my %gleList = ();
    if ($searchHdId) {
        $gleList{$searchHdId} = 1;
        $sql =
"SELECT hd_id FROM hierarchy_definition WHERE hd_type=${HD_SS_CONTENT} AND hd_parent_path LIKE '\%,${searchHdId},\%' OR hd_parent_id=${searchHdId}";

        #warn $sql;
        $sth = $dbh->prepare($sql);
        $sth->execute();
        while ( my $row = $sth->fetchrow_hashref ) {
            $gleList{ $row->{hd_id} } = 1;
        }
    }

    my @itemList = ();

    # build the query modifiers for users in workgroups
    my $useWorkgroupFilter = 0;
    my $reviewPerUserMap = map { $_ => 1 } @reviewPerUser;
    if (exists $reviewPerUserMap{$review_type_map{$user->{reviewType}}}) {
      # don't do a workgroup access check
    } else {

      if(  scalar(keys %{$user->{workGroups}}) 
        && defined($user->{workGroups}{$in{workGroupId}})
        && scalar(keys %{$user->{workGroups}{$in{workGroupId}}{filters}}) ) {
     
        # if in a current work group, a work group must be selected to get items
        if($in{workGroupId} eq '') {
          return [];
        }

        $useWorkgroupFilter = 1;
      }
    }

    # use a different query depending on whether they are doing a standards-based search

    if($searchHdId) {

      $sql = <<END_HERE;
      SELECT i.*, 
       (SELECT t2.ic_value FROM item_characterization AS t2 WHERE t2.ic_type=${OC_ITEM_STANDARD} AND t2.i_id=i.i_id LIMIT 1) AS gle_id,
       (SELECT t2.ic_value FROM item_characterization AS t2 WHERE t2.ic_type=${OC_MINOR_EDIT} AND t2.i_id=i.i_id LIMIT 1) AS minor_edit_flag
      FROM /*cde-filter*/ item AS i, item_characterization AS ic, hierarchy_definition AS hd 
      WHERE /*cde-filter*/ i.i_id=ic.i_id
        AND ic.ic_type=${OC_ITEM_STANDARD}
	AND ic.ic_value=hd.hd_id
	AND (hd.hd_parent_path LIKE '\%,${searchHdId},\%' OR hd.hd_parent_id=${searchHdId} OR hd.hd_id=${searchHdId})
	AND
END_HERE

    } else {

      $sql = <<END_HERE;
      SELECT i.*, 
       (SELECT t2.ic_value FROM item_characterization AS t2 WHERE t2.ic_type=${OC_ITEM_STANDARD} AND t2.i_id=i.i_id LIMIT 1) AS gle_id,
       (SELECT t2.ic_value FROM item_characterization AS t2 WHERE t2.ic_type=${OC_MINOR_EDIT} AND t2.i_id=i.i_id LIMIT 1) AS minor_edit_flag
      FROM /*cde-filter*/ item AS i 
      WHERE /*cde-filter*/
END_HERE
    }

    $sql .= " i.i_dev_state=${readDevState} AND i.ib_id=$in{itemBankId} AND i.i_is_old_version IS NULL";

    if( $in{itemFormat} ) {
	$sql .= " AND i.i_format=$in{itemFormat} ";
    }

    if( $in{publicationStatus} =~ /\w+/ ) {
	$sql .= " AND i.i_publication_status=$in{publicationStatus} ";
    }

    $in{passageId} ||= '';
    $sql .=
" AND i.i_id IN (SELECT t1.i_id FROM item_characterization AS t1 WHERE t1.ic_type=${OC_PASSAGE} AND t1.ic_value=$in{passageId})"
      if $in{passageId} ne '';
    $sql .= " AND i.i_author=$user->{id}" if $userType eq 'editor';
    $sql .= " AND i.ip_id=$in{projectId}"
      if exists( $in{projectId} )
          and $in{projectId} ne '';
    $sql .= " AND i.i_author=$in{editor}"
      if exists( $in{editor} )
          and $in{editor} ne '';

    # include filter for media/graphic/accessibility designer
    my %user_restrict_states = ( $DS_NEW_ART => 1,
                                 $DS_FIX_ART => 1,
			         $DS_NEW_MEDIA => 2,
			         $DS_FIX_MEDIA => 2,
			         $DS_NEW_ACCESSIBILITY => 3,
			         $DS_FIX_ACCESSIBILITY => 3);

    if(exists $user_restrict_states{$readDevState}) {

      $sql .= <<SQL; 
      AND i.i_id NOT IN (
        SELECT wsi_object_id FROM work_supplemental_info
	  WHERE wsi_object_type=${OT_ITEM}
	    AND wsi_work_type=$user_restrict_states{$readDevState}
	    AND wsi_u_id > 0
	    AND wsi_u_id != $user->{id}
      )
SQL
    }

    #. " AND i.i_lang = $in{language}"
    $sql .=
        " AND (i.i_review_lock=0 OR i.i_review_lifetime < "
      . $dbh->quote( &get_ts() ) . ")"
      . " ORDER BY i.i_external_id LIMIT 100";

    $sql = &makeQueryWithWorkgroupFilter($sql,$user->{workGroups}{$in{workGroupId}}, $OT_ITEM, 'i')
      if $useWorkgroupFilter;
    #warn $sql;
    $sth = $dbh->prepare($sql);
    $sth->execute()
      || warn( "Failed Query:" 
          . $sql
          . "\nError is "
          . $dbh->err . ","
          . $dbh->errstr );

    my %stdCache = ();
    while ( my $row = $sth->fetchrow_hashref ) {

        $row->{gle_id} = 0 unless defined $row->{gle_id};

        my $item = {};
        my $std =
          exists( $stdCache{ $row->{gle_id} } )
          ? $stdCache{ $row->{gle_id} }
          : &getStandard( $dbh, $row->{gle_id} );
        $stdCache{ $row->{gle_id} } = $std
          unless exists( $stdCache{ $row->{gle_id} } );

        $item->{id}          = $row->{i_id};
        $item->{ims_id}      = $row->{i_ims_id};
        $item->{name}        = $row->{i_external_id};
        $item->{item_writer}      = $users->{$row->{i_author}};
        $item->{publication_status}  = $publication_status{$row->{i_publication_status}};
        $item->{item_format}  = $item_formats{$row->{i_format}};
        $item->{description} = substr( $row->{i_description} || '', 0, 25 );
        $item->{author}      = $row->{i_author};

        $item->{$_} = '' foreach qw/last_state last_state_date last_user/;
        $item->{status} = {};

	$sql = <<SQL;
	SELECT is_last_dev_state, is_timestamp, is_u_id, i_notes FROM item_status 
	  WHERE i_id = $row->{i_id}
	  ORDER BY is_timestamp DESC LIMIT 2
SQL
        my $sth2 = $dbh->prepare($sql);
	$sth2->execute();

	my $is_last_status = 1;

	if(my $row2 = $sth2->fetchrow_hashref) {

          if($is_last_status) {
            $item->{last_state_value} = $row2->{is_last_dev_state};
            $item->{last_state} = $dev_states{ $row2->{is_last_dev_state} } || '';
            $item->{last_state_date} =
              substr( $row2->{is_timestamp}, 0, 10 );
            $item->{last_user} = $users->{ $row2->{is_u_id} || '' } || '';
            $item->{last_user} =~ s/(, \w).*$/$1/;

            if ( defined( $row2->{i_notes} ) and $row2->{i_notes} ne '' ) {
              $item->{status}{notes} = 1;
            }
          } else {
	    $item->{last_last_state_value} = $row2->{is_last_dev_state};
	  }
	  $is_last_status = 0;

	}

        $item->{last_save_user} =
          $users->{ $row->{i_last_save_user_id} || '' } || '';
        $item->{last_save_user} =~ s/(, \w).*$/$1/;
        $item->{gle}            = 'Not Assigned';
        $item->{gle_sort_order} = '99_99';

        #if ( exists $std->{$HD_GLE} ) {
            $item->{gle} =
"$std->{$HD_CONTENT_AREA}->{value} $std->{$HD_GRADE_LEVEL}->{value} / $std->{$HD_STANDARD_STRAND}->{value} / $std->{$HD_SS_CONTENT}->{value}";

            $sql =
"SELECT t1.hd_posn_in_parent, t1.hd_parent_id, (SELECT hd_posn_in_parent FROM hierarchy_definition WHERE hd_id=t1.hd_parent_id) AS parent_posn FROM hierarchy_definition AS t1 WHERE hd_id=$row->{gle_id}";
            $sth2 = $dbh->prepare($sql);
            $sth2->execute();

            if ( my $row2 = $sth2->fetchrow_hashref ) {
                $item->{gle_sort_order} = sprintf( "%02d_%02d",
                    $row2->{parent_posn}, $row2->{hd_posn_in_parent} );
            }
        #}

        if ( defined $row->{minor_edit_flag} ) {
            $item->{status}{minor_edit} = 1;
        }

        if ( $item->{last_state} ) {

	    if (    $row->{i_dev_state} == $DS_DEVELOPMENT
                and $item->{last_state_value} == $DS_CONTENT_REVIEW_1 ) {
                $item->{status}{reject_writer} = 1;
            }

	    if( $row->{i_dev_state} == $DS_CONTENT_REVIEW_1 &&
	        $item->{last_state_value} == $DS_DEVELOPMENT &&
	        defined($item->{last_last_state_value}) && 
		$item->{last_last_state_value} == $DS_CONTENT_REVIEW_1) {
	      $item->{status}{resubmit_writer} = 1;
	    }

	    if( $item->{last_state_value} == $DS_NEW_MEDIA ) {
	      $item->{status}{new_media} = 1;
	    }

	    if($item->{last_state_value} == $DS_FIX_MEDIA) {
	      $item->{status}{edit_media} = 1;
            }

	    if( $item->{last_state_value} == $DS_NEW_ART ) {
	      $item->{status}{new_art} = 1;
	    }

	    if( $item->{last_state_value} == $DS_FIX_ART) {
	      $item->{status}{edit_art} = 1;
	    }



        }

        push( @itemList, $item );
    }


    return \@itemList;
}

sub getUserWorkGroupsForBank {

  my $wg = shift;
  my $itemBankId = shift;

  my %out = map { $_ => $wg->{$_}{name} } grep { $wg->{$_}{bank} == $itemBankId } keys %$wg;
  return \%out;
}
1;
