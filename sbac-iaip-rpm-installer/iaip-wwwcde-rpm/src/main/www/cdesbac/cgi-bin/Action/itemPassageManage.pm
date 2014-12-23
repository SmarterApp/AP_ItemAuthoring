package Action::itemPassageManage;

use File::Glob ':glob';
use URI::Escape;
use ItemConstants;
use UrlConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => join (' ', $q->param($_) ) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $thisUrl         = "${orcaUrl}cgi-bin/itemPassageManage.pl";
  our $passagesPerPage = 30;
  
  our $sth;
  our $sql;

  # Authorize user (must be user type UT_ITEM_EDITOR and be an admin)
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and $user->{adminType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth ] ];
  }
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{myAction}   = ''  unless exists $in{myAction};
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};
  
  our $editors = &getEditors($dbh, $in{itemBankId});
  our $projects = &getProjects( $dbh, $in{itemBankId} );
  
  if ( $in{myAction} eq 'rename' ) {
  
      # Only rename the first item
      my @passageIdArray = split / /, $in{'passageId[]'};
      my $passageId      = $passageIdArray[0];
      my $oldPassageName = '';
  
      # Make sure they didn't hit 'Rename' accidentally
      if ( $in{newPassageName} eq '' ) {
        $in{message} = "Cannot Rename Passage to a blank name.";
        return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
      }
  
  # Make sure there are no duplicates, but allow a passage to be renamed to a differently-cased
  # version of itself
      $sql = "SELECT p_name FROM passage WHERE p_id=${passageId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
      if ( my $row = $sth->fetchrow_hashref ) {
          $oldPassageName = $row->{p_name};
      }
  
      if ( $in{newPassageName} !~ /^$oldPassageName$/i ) {
  
          $sql =
              "SELECT p_id FROM passage WHERE ib_id=$in{itemBankId}"
            . " AND p_name="
            . $dbh->quote( $in{newPassageName} );
          $sth = $dbh->prepare($sql);
          $sth->execute();
          if ( my $row = $sth->fetchrow_hashref ) {
            $in{message} =
                "Cannot Rename Passage, the name already exists in target bank.";
            return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
          }
      }
  
      $sql =
          "UPDATE passage SET p_name="
        . $dbh->quote( $in{newPassageName} )
        . " WHERE p_id=${passageId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $in{message} = "Renamed '${oldPassageName}' to '$in{newPassageName}'";
  
      &addPassageAction($passageId, 'Passage Admin', 'Renamed Passage');
  }
  elsif ( $in{myAction} eq 'move' ) {
  
      if ( $in{itemBankId} eq '' or $in{targetBankId} eq '' ) {
          $in{message} = "Unable to move Passages (no item bank selected).";
      }
      else {
  
          my @passageIdArray = split / /, $in{'passageId[]'};
  
          # First, make sure there are no duplicates
          $sql =
            "SELECT p_id FROM passage WHERE ib_id=$in{targetBankId} AND p_name IN"
            . " (SELECT p_name FROM passage WHERE p_id IN ("
            . join( ',', @passageIdArray ) . "))";
          $sth = $dbh->prepare($sql);
          $sth->execute();
          if ( my $row = $sth->fetchrow_hashref ) {
              $in{message} =
                "Cannot Move Passages. Some names already exist in target bank.";
              return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
          }
  
          foreach my $passageId (@passageIdArray) {
              $sql = "SELECT p_url, ib_id FROM passage WHERE p_id=${passageId}";
              $sth = $dbh->prepare($sql);
              $sth->execute();
  
              if ( my $row = $sth->fetchrow_hashref ) {
                  my $xmlSource   = ${webPath} . $row->{p_url};
                  my $passageData = '';
                  open SOURCE, "<${xmlSource}";
                  while (<SOURCE>) {
                      chomp;
                      $passageData .= $_;
                  }
                  close SOURCE;
  
                  my $fromLib = "lib$row->{ib_id}";
                  my $toLib   = "lib$in{targetBankId}";
                  $passageData =~ s/\/$fromLib\//\/$toLib\//gs;
  
                  open SOURCE, ">${xmlSource}";
                  print SOURCE $passageData;
                  close SOURCE;
  
                  my $newUrl = $row->{p_url};
                  $newUrl =~ s/\/$fromLib\//\/$toLib\//gs;
  
                  rename(
                      "${passagePath}/${fromLib}/p${passageId}.htm",
                      "${passagePath}/${toLib}/p${passageId}.htm"
                  );
                  rename(
                      "${passagePath}/${fromLib}/images/p${passageId}",
                      "${passagePath}/${toLib}/images/p${passageId}"
                  );
  
                  $sql =
                      "UPDATE passage SET ib_id=$in{targetBankId}, p_url="
                    . $dbh->quote($newUrl)
                    . " WHERE p_id=${passageId}";
                  $sth = $dbh->prepare($sql);
                  $sth->execute();
              }
  
              &addPassageAction($passageId, 'Passage Admin', 'Moved between Programs');
          }
  
          $in{message} =
            "Moved " . scalar(@passageIdArray) . " Passages successfully.";
      }
  }
  elsif ( $in{myAction} eq 'remove' ) {
  
      my @passageIdArray = split / /, $in{'passageId[]'};
  
      foreach my $passageId (@passageIdArray) {
          $sql = "SELECT * FROM passage WHERE p_id=${passageId}";
          $sth = $dbh->prepare($sql);
          $sth->execute();
  
          if ( my $row = $sth->fetchrow_hashref ) {
  
              my $fromLib = "lib$row->{ib_id}";
  
              unlink("${passagePath}/${fromLib}/p${passageId}.htm");
  
              foreach my $file (
                  bsd_glob("${passagePath}/${fromLib}/images/p${passageId}/*") )
              {
                  unlink($file);
              }
  
              rmdir("${passagePath}/${fromLib}/images/p${passageId}/");
  
              $sql = "DELETE FROM passage WHERE p_id=${passageId} LIMIT 1";
              my $sth2 = $dbh->prepare($sql);
              $sth2->execute();
  
              $sql =
  "DELETE FROM object_characterization WHERE oc_object_type=${OC_PASSAGE}"
                . " AND oc_object_id=${passageId}";
              $sth2 = $dbh->prepare($sql);
              $sth2->execute();
  
              $sql =
  "DELETE FROM item_characterization WHERE ic_type=${OC_PASSAGE} AND ic_value=${passageId}";
              $sth2 = $dbh->prepare($sql);
              $sth2->execute();
  
              $sql = sprintf('INSERT INTO deleted_passage SET p_id=%d, ib_id=%d, p_name=%s, p_dev_state=%d, p_publication_status=%d',
  	             $passageId,
  		     $row->{ib_id},
  		     $dbh->quote($row->{p_name}),
  		     $row->{p_dev_state},
  		     $row->{p_publication_status});
              $sth2 = $dbh->prepare($sql);
              $sth2->execute();
  	    $sth2->finish;
          }
  	$sth->finish;
  
  	&addPassageAction($passageId, 'Passage Admin', 'Delete Passage');
      }
  
      $in{message} =
        "Removed " . scalar(@passageIdArray) . " Passages successfully.";
  }
  elsif ( $in{myAction} eq 'assignAuthor' ) {
      my @passageIdArray = split / /, $in{'passageId[]'};
  
      if ( scalar @passageIdArray ) {
          $sql = "UPDATE passage SET p_author=$in{passageWriter} WHERE p_id IN ("
            . join( ',', @passageIdArray ) . ')';
          $sth = $dbh->prepare($sql);
          $sth->execute();
  
      }
  
      foreach my $passageId (@passageIdArray) {
        &addPassageAction($passageId, 'Passage Admin', 'Set Author');
      }
  
      $in{message} =
        "Assigned " . scalar(@passageIdArray) . " Passages successfully.";
  }
  elsif ( $in{myAction} eq 'assignProject' ) {
      my @passageIdArray = split / /, $in{'passageId[]'};
  
      $sql = "UPDATE passage SET ip_id=$in{itemProject} WHERE p_id IN ("
        . join( ',', @passageIdArray ) . ')';
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      foreach my $passageId (@passageIdArray) {
        &addPassageAction($passageId, 'Passage Admin', 'Set Project');
      }
  
      $in{message} =
        "Assigned " . scalar(@passageIdArray) . " Passages successfully.";
  }
  elsif ( $in{myAction} eq 'assignState' ) {
      my @passageIdArray = split / /, $in{'passageId[]'};
  
      if ( scalar @passageIdArray ) {
          $sql = "UPDATE passage SET p_dev_state=$in{devState} WHERE p_id IN ("
            . join( ',', @passageIdArray ) . ')';
          $sth = $dbh->prepare($sql);
          $sth->execute();
      }
  
      foreach my $passageId (@passageIdArray) {
        &addPassageAction($passageId, 'Passage Admin', 'Set Development State');
      }
  
      $in{message} =
        "Assigned " . scalar(@passageIdArray) . " Items successfully.";
  }
  elsif ( $in{myAction} eq 'undoReviewLock' ) {
      my @passageIdArray = split / /, $in{'passageId[]'};
  
      $sql = 'UPDATE passage SET p_review_lock=0 WHERE p_id IN ('
        . join( ',', @passageIdArray ) . ')';
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      $in{message} =
        "Unlocked " . scalar(@passageIdArray) . " Passages successfully.";
  }
  
  unless ( defined $in{itemBankId} and $in{itemBankId} ne '' ) {
      $in{message} = "Please Select an Item Bank.";
      return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  my $step = defined( $in{step} ) ? $in{step} + $passagesPerPage : 0;
  $step = 0 if $step < 0;
  $in{step} = $step;
  
  $sql =
    "SELECT * FROM passage WHERE ib_id=$in{itemBankId}"
    . ( defined( $in{idMatch} )
        && $in{idMatch} ne '' ? ' AND p_name LIKE \'%' . $in{idMatch} . '%\''
      : '' )
    . ( exists( $in{contentAreaFilter} )
        && $in{contentAreaFilter} ne ''
      ? " AND $in{contentAreaFilter}=(SELECT oc_int_value FROM object_characterization WHERE oc_object_id=p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_CONTENT_AREA} LIMIT 1)"
      : '' )
    . ( exists( $in{gradeLevelFilter} )
        && $in{gradeLevelFilter} ne ''
      ? " AND $in{gradeLevelFilter}=(SELECT oc_int_value FROM object_characterization WHERE oc_object_id=p_id AND oc_object_type=${OT_PASSAGE} AND oc_characteristic=${OC_GRADE_LEVEL} LIMIT 1)"
      : '' )
    . ( exists( $in{itemProjectFilter} )
        && $in{itemProjectFilter} ne '' ? ' AND ip_id=' . $in{itemProjectFilter}
      : '' )
    . ( exists( $in{devStateFilter} )
        && $in{devStateFilter} ne '' ? ' AND p_dev_state=' . $in{devStateFilter}
      : '' )
    . " ORDER BY p_name  LIMIT ${step},${passagesPerPage}";
  #warn $sql;
  $sth = $dbh->prepare($sql);
  $sth->execute();
  $in{passages} = [];
  
  while ( my $row = $sth->fetchrow_hashref ) {
    my %newPassage = ();
#added for edit(Select menu)
     $sqlTemp = "select DISTINCT i.i_format from item as i,passage_item_set as pis where pis.p_id=? and i.i_id=pis.i_id;";
    my $sthTemp = $dbh->prepare($sqlTemp);
          $sthTemp->execute($row->{p_id});
           my $rowTemp = $sthTemp->fetchrow_hashref; 
		 $newPassage{iformat} = $rowTemp->{i_format} || 0;
#edit end here 
      
      $newPassage{id}             = $row->{p_id};
      $newPassage{external_id}    = $row->{p_name};
      $newPassage{genre}          = $genres{ $row->{p_genre} };
      $newPassage{description}    = $row->{p_summary} || '';
      $newPassage{dev_state}      = $dev_states{ $row->{p_dev_state} };
      $newPassage{passage_writer} = '';
      if ( $row->{p_author} ) {
          $sql = 'SELECT * FROM user WHERE u_id=' . $row->{p_author};
          my $sth2 = $dbh->prepare($sql);
          $sth2->execute();
          if ( my $row2 = $sth2->fetchrow_hashref ) {
              $newPassage{passage_writer} =
                "$row2->{u_last_name}, $row2->{u_first_name}";
          }
      }
      $newPassage{itemProject} = $projects->{ $row->{ip_id} } || '';
      $newPassage{reviewLock} =
        (      $row->{p_review_lock} eq '0'
            || $row->{p_review_lifetime} lt &get_ts() ? '0' : '1' );
      push @{ $in{passages} }, \%newPassage;
  }
  
  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
}

### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    my $params = shift;
    my $msg    = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;'>" . $params->{message} . "</div>"
        : "" );

    my $itemBankId =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : "0" );
    my $step    = defined( $params->{step} )    ? $params->{step}    : 0;
    my $idMatch = defined( $params->{idMatch} ) ? $params->{idMatch} : '';

    if ( $step < 0 ) { $step = 0; }

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;
    my %filteredDevStates =  map { $_ => $dev_states{$_} } grep { exists $dev_states{$_} } @dev_states_workflow_ordered_keys;

    my $itemBankHtml =
      &hashToSelect( 'itemBankId', \%itemBanks, $itemBankId, 'resetFilter();',
        'null', '', );
    my $targetBankHtml =
      &hashToSelect( 'targetBankId', \%itemBanks, '', '', 'null', '', );
    my $editorHtml =
      &hashToSelect( 'passageWriter', $editors, '', '', '', 'value', '', );
    my $devStateHtml =
      &hashToSelect( 'devState', \%filteredDevStates, '', '', '', 'value', '');
    my $projectHtml =
      &hashToSelect( 'itemProject', $projects, '', '', '', 'value', '', );

    my $contentAreaFilterHtml = &hashToSelect(
        'contentAreaFilter',
        $const[$OC_CONTENT_AREA],
        $params->{contentAreaFilter} || '',
        'resetFilter();', 'null:All', '', 
    );
    my $gradeLevelFilterHtml =
      &hashToSelect( 'gradeLevelFilter', $const[$OC_GRADE_LEVEL],
        $params->{gradeLevelFilter} || '',
        'resetFilter();', 'null:All', '', );
    my $projectFilterHtml =
      &hashToSelect( 'itemProjectFilter', $projects,
        $params->{itemProjectFilter} || '',
        '', 'null:All', 'value', );
    my $devStateFilterHtml =
      &hashToSelect( 'devStateFilter', \%filteredDevStates,
        $params->{devStateFilter} || '',
        '', 'null:All', 'value', );

    unless ( defined $params->{passages} ) {
        $params->{passages} = [];
    }

    my $safeUrl =
      uri_escape( "${thisUrl}?itemBankId=${itemBankId}&step="
          . ( $step - $passagesPerPage )
          . "&idMatch="
          . ( $idMatch || '' )
          . "&contentAreaFilter="
          . ( $params->{contentAreaFilter} || '' )
          . "&gradeLevelFilter="
          . ( $params->{gradeLevelFilter} || '' )
          . "&itemProjectFilter="
          . ( $params->{itemProjectFilter} || '' )
          . "&devStateFilter="
          . ( $params->{devStateFilter} || '' ) );

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html>
  <head>
    <title>Passage Administration</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      function myOpen(name,url,w,h)
      {
    var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(370,180);
    return true;
      }

      function resetFilter() {
        document.form1.step.value = -${passagesPerPage};
        document.form1.idMatch.value = '';
    document.form1.submit();
    return true;
      }
      
      function filterResults() {
        document.form1.step.value = -${passagesPerPage};
    document.form1.submit();
    return true;
      }

      function doMoveSubmit() {
        document.form1.step.value -= ${passagesPerPage};
        document.form1.myAction.value = 'move';
    document.form1.submit();
    return true;
      }
      
      function doRemoveSubmit() {
        var answer = confirm("Remove selected Passages?");
    if(answer) {
      document.form1.step.value -= ${passagesPerPage};
          document.form1.myAction.value = 'remove';
      document.form1.submit();
      return true;
        } else {
      return false;
        }
      }
      
      function renamePassage() {
    document.form1.step.value -= ${passagesPerPage};
        document.form1.myAction.value = 'rename';   
    document.form1.submit();
    return true;
      }
      
            function doAuthorSubmit() {
    document.form1.step.value -= ${passagesPerPage};
        document.form1.myAction.value = 'assignAuthor'; 
    document.form1.submit();
    return true;
      }
            
            function doProjectSubmit() {
    document.form1.step.value -= ${passagesPerPage};
        document.form1.myAction.value = 'assignProject';    
    document.form1.submit();
    return true;
      }
            
            function doStateSubmit() {
    document.form1.step.value -= ${passagesPerPage};
        document.form1.myAction.value = 'assignState';  
    document.form1.submit();
    return true;
      }
            
            function doReviewLockSubmit() {
    document.form1.step.value -= ${passagesPerPage};
        document.form1.myAction.value = 'undoReviewLock';   
    document.form1.submit();
    return true;
      }

      function targetBankIdSelect() { 
        return true; 
      }

    /* iformat is added for pass iformat to pl page */
    function passageAction(obj, id, iformat, externalId) {
        var option = obj.options[obj.selectedIndex].value;

        if (option == 'view') {
            myOpen('passageWin', '${orcaUrl}cgi-bin/passageView.pl?passageId=' + id, 700, 500);
        }

        if (option == 'edit') {
            parent.rightFrame.document.location.href = 
                '${orcaUrl}cgi-bin/itemPassageCreate.pl?itemBankId=${itemBankId}&pname=' + externalId + '&iformat=' + iformat +
                '&myAction=edit&furl=${safeUrl}';
        }

        if (option == 'accessibility') {
            parent.rightFrame.document.location.href = '${javaUrl}AccessibilityTagging.jsf?passage=' + id;
        }
        if (option == 'history') {
            //parent.rightFrame.document.location.href = '${javaUrl}Report.jsf?name=/reports/PassageHistoryReport&p_PassageId=' + id;
            myOpen('history', '${javaUrl}Report.jsf?name=/reports/PassageHistoryReport&p_PassageId=' + id, 850, 500); 
        }

        obj.selectedIndex = 0;
    }

    //-->
    </script>
  </head>
  <body>
    <div class="title">Passage Management</div>
    ${msg}
    <form name="form1" action="${thisUrl}" method="POST">
      <input type="hidden" name="step" value="${step}" />
      <input type="hidden" name="myAction" value="" />
      <p>
    <table border="1" cellspacing="3" cellpadding="3">
    <tr><td>
      <table id="header" width="100%" border="0" cellspacing="3" cellpadding="3" class="no-style">
        <tr>
      <td><span class="text">Source:</span></td>
      <td>${itemBankHtml}</td>
      <td>&nbsp;&nbsp;</td> 
      <td><span class="text">Target:</span></td>
      <td>${targetBankHtml}</td>
      <td>&nbsp;&nbsp;</td>
      <td><input type="button" value="Move" style="width: 70px;" onClick="return doMoveSubmit();" /></td>
      <td><input type="button" value="Delete" style="width: 70px;" onClick="return doRemoveSubmit();" /></td>
    </tr>
      </table>
    </td></tr>
    <tr><td style="text-align:left;">
      <table id="body" border="0" cellspacing="3" cellpadding="3" class="no-style">
        <tr>
            <td style="text-align:right;">Name:</td>
            <td style="text-align:left;"><input type="text" size="14" name="idMatch" value="${idMatch}" /></td>
            <td>&nbsp;&nbsp;</td>
            <td style="text-align:right;">Dev State:</td>
            <td style="text-align:left;" colspan="5">${devStateFilterHtml}</td>
          </tr>
        <tr>
                  <td style="text-align:right;">Subject:</td>
                    <td style="text-align:left;">${contentAreaFilterHtml}</td>
            <td>&nbsp;&nbsp;</td>
            <td style="text-align:right;">Grade:</td>
            <td style="text-align:left;">${gradeLevelFilterHtml}</td>
                    <td colspan="3">&nbsp;&nbsp;</td>
            <td style="text-align:left;"><input type="button" value="Filter Results" style="width: 120px;" onClick="filterResults();" /></td>
          </tr>
      </table>
    </td></tr>
    </table></p> 
    <p>
    <table id="results" border="1" cellspacing="3" cellpadding="3">
      <tr>
        <th class="data">Select</th>
        <th class="data">Name</th>
        <th class="data">Genre</th>
        <th class="data">Summary</th>
        <th class="data">Dev State</th>
        <th class="data">Author</th>
        <th class="data"></th>
      </tr>
END_HERE

    foreach ( @{ $params->{passages} } ) {

        $_->{description} = '&nbsp;' if $_->{description} eq '';
        $_->{dev_state} = '&nbsp;' unless exists $_->{dev_state};
        $_->{passage_writer} = '&nbsp;' if $_->{passage_writer} eq '';
        $_->{itemProject}    = '&nbsp;' if $_->{itemProject}    eq '';
        $_->{genre}          = '&nbsp;' if $_->{genre}          eq '';

        for my $field_name (
            qw( external_id genre description dev_state passage_writer itemProject )
          )
        {
            $_->{$field_name} ||= '&nbsp;';
        }
#added for edit(Select option)
         if($_->{iformat}==5){
           $psgi_out .= '<tr>'
          . '<td style="width:40px;"><input type="checkbox" name="passageId[]" value="'
          . $_->{id}
          . '" /></td>'
          . '<td class="data">'
          . $_->{external_id} .'</td>'
          . '<td class="data">'
          . $_->{genre} . '</td>'
          . '<td class="data" style="width:200px;">'
          . $_->{description} . '</td>'
          . '<td class="data">'
          . $_->{dev_state} . '</td>'
          . '<td class="data">'
          . $_->{passage_writer} . '</td>'
          . '<td class="data" style="width:100px;">'
          . '<select name="passageActionSelect" onChange="passageAction(this, '
          . $_->{id} . ', '
		  . $_->{iformat}.', '
          . '\'' . uri_escape( $_->{external_id}, "^A-Za-z0-9" ) 
          . '\');" style="width:150px" >' 
          . '<option value="">-- Options --</option>' 
          . '<option value="edit">Edit</option>'
          . '</select>' 
          . ( $_->{reviewLock} eq '1' ? ' *' : '' ) . '</td>'
          . '</tr>';

}
else{
        $psgi_out .= '<tr>'
          . '<td style="width:40px;"><input type="checkbox" name="passageId[]" value="'
          . $_->{id}
          . '" /></td>'
          . '<td class="data">'
          . $_->{external_id} .'</td>'
          . '<td class="data">'
          . $_->{genre} . '</td>'
          . '<td class="data" style="width:200px;">'
          . $_->{description} . '</td>'
          . '<td class="data">'
          . $_->{dev_state} . '</td>'
          . '<td class="data">'
          . $_->{passage_writer} . '</td>'
          . '<td class="data" style="width:100px;">'
          . '<select name="passageActionSelect" onChange="passageAction(this, '
          . $_->{id} . ', '
		  . $_->{iformat}.', '
          . '\'' . uri_escape( $_->{external_id}, "^A-Za-z0-9" ) 
          . '\');" style="width:150px" >' 
          . '<option value="">-- Options --</option>' 
          . '<option value="edit">Edit</option>'
          . '<option value="view">View</option>'
          . '<option value="accessibility">Accessibility</option>'
          . '<option value="history">Passage History Report</option>'
          . '</select>' 
          . ( $_->{reviewLock} eq '1' ? ' *' : '' ) . '</td>'
          . '</tr>';
    }
#end here
}

    $psgi_out .= <<END_HERE;
    </table>
    <table id="footer" border="0" cellspacing="4" cellpadding="2">
      <tr>
    <td align="left" style="width:400px;">
    <input type="button" value="Last ${passagesPerPage} Passages" onClick="document.form1.step.value -= 2 * ${passagesPerPage}; document.form1.submit();" />&nbsp;&nbsp;&nbsp;
    <input type="button" value="Next ${passagesPerPage} Passages" onClick="document.form1.submit();" /></td>
      </tr>
    </table></p>
        <p>
    <table border="1" cellspacing="0" cellpadding="2">
    <tr><td>
      <table id="operations" border="0" cellspacing="3" cellpadding="3">
        <tr>
      <td><span class="text">Rename:</td>
      <td><input type="text" size="25" name="newPassageName" /></td>
      <td><input type="button" style="width:130px;" value="Rename Selected" onClick="renamePassage();" /></td>
    </tr>
        <tr>
          <td><span class="text">Author:</span></td>
        <td>${editorHtml}</td>
        <td><input style="width:120px;" type="button" value="Assign Author" onClick="doAuthorSubmit();" /></td>
      </tr>
        <tr>
          <td><span class="text">Dev&nbsp;State:</span></td>
          <td>${devStateHtml}</td>
        <td><input style="width:120px;" type="button" value="Assign State" onClick="doStateSubmit();" /></td>
        </tr>
        <tr>
          <td><span class="text">Review:</span></td>
          <td>* next to Edit = Locked</td>
        <td><input style="width:120px;" type="button" value="Unlock Selected" onClick="doReviewLockSubmit();" /></td>
        </tr>
      </table>
    </td></tr>
    </table> </p>
    </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}

sub addPassageAction {

  my $id = shift;
  my $process = shift;
  my $detail = shift;

  my $sql = sprintf('INSERT INTO user_action_passage SET p_id=%d, u_id=%d, uap_process=%s, uap_detail=%s',
             $id,
	     $user->{id},
	     $dbh->quote($process),
	     $dbh->quote($detail));
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  $sth->finish;
}
1;