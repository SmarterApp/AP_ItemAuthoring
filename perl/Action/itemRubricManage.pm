package Action::itemRubricManage;

use File::Glob ':glob';
use URI::Escape;
use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => join (' ', $q->param($_) ) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $thisUrl        = "${orcaUrl}cgi-bin/itemRubricManage.pl";
  our $rubricsPerPage = 30;
  
  our $sth;
  our $sql;
  
  # Authorize user (must be user type UT_ITEM_EDITOR and be an admin)
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and $user->{reviewType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ];
  }
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{myAction}   = ''  unless exists $in{myAction};
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};
  
  our $editors = &getEditors($dbh, $in{ItemBankId});
  
  if ( $in{myAction} eq 'rename' ) {
  
      # Only rename the first item
      my @rubricIdArray = split / /, $in{'rubricId[]'};
      my $rubricId      = $rubricIdArray[0];
      my $oldRubricName = '';
  
      # Make sure they didn't hit 'Rename' accidentally
      if ( $in{newRubricName} eq '' ) {
        return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
      }
  
  # Make sure there are no duplicates, but allow a rubric to be renamed to a differently-cased
  # version of itself
      $sql = "SELECT sr_name FROM scoring_rubric WHERE sr_id=${rubricId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
      if ( our $row = $sth->fetchrow_hashref ) {
          $oldRubricName = $row->{sr_name};
      }
  
      if ( $in{newRubricName} !~ /^$oldRubricName$/i ) {
  
          $sql =
              "SELECT sr_id FROM scoring_rubric WHERE ib_id=$in{itemBankId}"
            . " AND sr_name="
            . $dbh->quote( $in{newRubricName} );
          $sth = $dbh->prepare($sql);
          $sth->execute();
          if ( our $row = $sth->fetchrow_hashref ) {
              $in{message} =
                "Cannot Rename Rubric, the name already exists in target bank.";
              return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
          }
      }
  
      $sql =
          "UPDATE scoring_rubric SET sr_name="
        . $dbh->quote( $in{newRubricName} )
        . " WHERE sr_id=${rubricId}";
      $sth = $dbh->prepare($sql);
      $sth->execute();
      $in{message} = "Renamed '${oldRubricName}' to '$in{newRubricName}'";
  }
  elsif ( $in{myAction} eq 'move' ) {
  
      if ( $in{itemBankId} eq '' or $in{targetBankId} eq '' ) {
          $in{message} = "Unable to move Rubrics (no item bank selected).";
      }
      else {
  
          my @rubricIdArray = split / /, $in{'rubricId[]'};
  
          # First, make sure there are no duplicates
          $sql =
  "SELECT sr_id FROM scoring_rubric WHERE ib_id=$in{targetBankId} AND sr_name IN"
            . " (SELECT sr_name FROM scoring_rubric WHERE sr_id IN ("
            . join( ',', @rubricIdArray ) . "))";
          $sth = $dbh->prepare($sql);
          $sth->execute();
          if ( my $row = $sth->fetchrow_hashref ) {
              $in{message} =
                "Cannot Move Rubrics. Some names already exist in target bank.";
              return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
          }
  
          foreach my $rubricId (@rubricIdArray) {
              $sql =
  "SELECT sr_url, ib_id FROM scoring_rubric WHERE sr_id=${rubricId}";
              $sth = $dbh->prepare($sql);
              $sth->execute();
  
              if ( my $row = $sth->fetchrow_hashref ) {
                  my $xmlSource  = ${webPath} . $row->{sr_url};
                  my $rubricData = '';
                  open SOURCE, "<${xmlSource}";
                  while (<SOURCE>) {
                      chomp;
                      $rubricData .= $_;
                  }
                  close SOURCE;
  
                  my $fromLib = "lib$row->{ib_id}";
                  my $toLib   = "lib$in{targetBankId}";
                  $rubricData =~ s/\/$fromLib\//\/$toLib\//gs;
  
                  open SOURCE, ">${xmlSource}";
                  print SOURCE $rubricData;
                  close SOURCE;
  
                  my $newUrl = $row->{sr_url};
                  $newUrl =~ s/\/$fromLib\//\/$toLib\//gs;
  
                  rename(
                      "${rubricPath}/${fromLib}/r${rubricId}.htm",
                      "${rubricPath}/${toLib}/r${rubricId}.htm"
                  );
                  rename(
                      "${rubricPath}/${fromLib}/images/r${rubricId}",
                      "${rubricPath}/${toLib}/images/r${rubricId}"
                  );
  
                  $sql =
                      "UPDATE scoring_rubric SET ib_id=$in{targetBankId}, sr_url="
                    . $dbh->quote($newUrl)
                    . " WHERE sr_id=${rubricId}";
                  $sth = $dbh->prepare($sql);
                  $sth->execute();
              }
          }
  
          $in{message} =
            "Moved " . scalar(@rubricIdArray) . " Rubrics successfully.";
      }
  }
  elsif ( $in{myAction} eq 'remove' ) {
  
      my @rubricIdArray = split / /, $in{'rubricId[]'};
  
      foreach my $rubricId (@rubricIdArray) {
          $sql = "SELECT * FROM scoring_rubric WHERE sr_id=${rubricId}";
          $sth = $dbh->prepare($sql);
          $sth->execute();
  
          if ( my $row = $sth->fetchrow_hashref ) {
  
              my $fromLib = "lib$row->{ib_id}";
  
              unlink("${rubricPath}/${fromLib}/r${rubricId}.htm");
  
              foreach my $file (
                  bsd_glob("${rubricPath}/${fromLib}/images/r${rubricId}/*") )
              {
                  unlink($file);
              }
  
              rmdir("${rubricPath}/${fromLib}/images/r${rubricId}/");
  
              $sql = "DELETE FROM scoring_rubric WHERE sr_id=${rubricId} LIMIT 1";
              $sth = $dbh->prepare($sql);
              $sth->execute();
  
              $sql =
  "DELETE FROM object_characterization WHERE oc_object_type=${OC_RUBRIC}"
                . " AND oc_object_id=${rubricId}";
              $sth = $dbh->prepare($sql);
              $sth->execute();
          }
      }
  
      $in{message} =
        "Removed " . scalar(@rubricIdArray) . " Rubrics successfully.";
  }
  
  unless ( defined $in{itemBankId} and $in{itemBankId} ne '' ) {
    $in{message} = "Please Select an Item Bank.";
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  my $step = defined( $in{step} ) ? $in{step} + $rubricsPerPage : 0;
  $step = 0 if $step < 0;
  $in{step} = $step;
  
  $sql =
    "SELECT * FROM scoring_rubric WHERE ib_id=$in{itemBankId}"
    . ( defined( $in{idMatch} )
        && $in{idMatch} ne '' ? ' AND sr_name LIKE \'%' . $in{idMatch} . '%\''
      : '' )
    . ( exists( $in{contentAreaFilter} )
        && $in{contentAreaFilter} ne ''
      ? " AND $in{contentAreaFilter}=(SELECT oc_int_value FROM object_characterization WHERE oc_object_id=sr_id AND oc_object_type=${OT_RUBRIC} AND oc_characteristic=${OC_CONTENT_AREA} LIMIT 1)"
      : '' )
    . ( exists( $in{gradeLevelFilter} )
        && $in{gradeLevelFilter} ne ''
      ? " AND $in{gradeLevelFilter}=(SELECT oc_int_value FROM object_characterization WHERE oc_object_id=sr_id AND oc_object_type=${OT_RUBRIC} AND oc_characteristic=${OC_GRADE_LEVEL} LIMIT 1)"
      : '' )
    . " ORDER BY sr_name  LIMIT ${step},${rubricsPerPage}";
  $sth = $dbh->prepare($sql);
  $sth->execute();
  $in{rubrics} = [];
  
  while ( my $row = $sth->fetchrow_hashref ) {
      my %newRubric = ();
      $newRubric{id}          = $row->{sr_id};
      $newRubric{external_id} = $row->{sr_name};
      $newRubric{description} = $row->{sr_description};
      push @{ $in{rubrics} }, \%newRubric;
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

    my $itemBankHtml =
      &hashToSelect( 'itemBankId', \%itemBanks, $itemBankId, 'resetFilter();',
        'null', '', );
    my $targetBankHtml =
      &hashToSelect( 'targetBankId', \%itemBanks, '', '', 'null', '', );

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

    unless ( defined $params->{rubrics} ) {
        $params->{rubrics} = [];
    }

    my $safeUrl =
      uri_escape( "${thisUrl}?itemBankId=${itemBankId}&step="
          . ( $step - $rubricsPerPage )
          . "&idMatch="
          . ( $idMatch || '' )
          . "&contentAreaFilter="
          . ( $params->{contentAreaFilter} || '' )
          . "&gradeLevelFilter="
          . ( $params->{gradeLevelFilter} || '' ) );

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Rubric Administration</title>
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
        document.form1.step.value = -${rubricsPerPage};
        document.form1.idMatch.value = '';
	document.form1.submit();
	return true;
      }
      
      function filterResults() {
        document.form1.step.value = -${rubricsPerPage};
	document.form1.submit();
	return true;
      }

      function doMoveSubmit() {
        document.form1.step.value -= ${rubricsPerPage};
        document.form1.myAction.value = 'move';
	document.form1.submit();
	return true;
      }
      
      function doRemoveSubmit() {
        var answer = confirm("Remove selected Rubrics?");
	if(answer) {
	  document.form1.step.value -= ${rubricsPerPage};
          document.form1.myAction.value = 'remove';
	  document.form1.submit();
	  return true;
        } else {
	  return false;
        }
      }
      
      function renameRubric() {
	document.form1.step.value -= ${rubricsPerPage};
        document.form1.myAction.value = 'rename';	
	document.form1.submit();
	return true;
      }
      
      function targetBankIdSelect() { 
        return true; 
      }
    //-->
    </script>
  </head>
  <body>
    <div class="title">Rubric Management</div>
    ${msg}
    <form name="form1" action="${thisUrl}" method="POST">
      <input type="hidden" name="step" value="${step}" />
      
      <input type="hidden" name="myAction" value="" />
    <table border="1" cellspacing="3" cellpadding="3">
    <tr><td>
      <table width="100%" border="0" cellspacing="3" cellpadding="3" class="no-style">
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
    <tr><td align="left">
        <p style="margin-top:3px;margin-bottom:3px;" align="left">
	        &nbsp;&nbsp;Name:&nbsp;&nbsp;
	        <input type="text" size="30" name="idMatch" value="${idMatch}" class="long-value"/>
	      </p>
      <table width="100%" border="0" cellspacing="3" cellpadding="3" class="no-style">
        <tr>
				  <td style="text-align:right;">Subject:</td>
					<td style="text-align:left;">${contentAreaFilterHtml}</td>
	        <td>&nbsp;&nbsp;</td>
	        <td style="text-align:right;">Grade:</td>
	        <td style="text-align:left;">${gradeLevelFilterHtml}</td>
					<td>&nbsp;&nbsp;</td>
	        <td><input type="button" value="Filter Results" style="width: 120px;" onClick="filterResults();" /></td>
	      </tr>
      </table>
    </td></tr>
    </table> 
    <br />
    <table border="1" cellspacing="3" cellpadding="3">
      <tr>
        <th class="data">Select</th>
        <th class="data">Name</th>
        <th class="data">Summary</th>
	<th class="data">Edit</th>
      </tr>
END_HERE

    foreach ( @{ $params->{rubrics} } ) {

        $_->{description} = '&nbsp;' if $_->{description} eq '';

        for my $field_name (qw( external_id description )) {
            $_->{$field_name} ||= '&nbsp;';
        }

        $psgi_out .= '<tr>'
          . '<td style="width:40px;"><input type="checkbox" name="rubricId[]" value="'
          . $_->{id}
          . '" /></td>'
          . '<td class="data">'
          . $_->{external_id} . '</td>'
          . '<td class="data" style="width:200px;">'
          . $_->{description} . '</td>'
          . '<td style="width:55px;"><input type="button" value="Edit" onClick="parent.rightFrame.document.location.href=\''
          . $orcaUrl
          . 'cgi-bin/itemRubricCreate.pl?itemBankId='
          . $itemBankId
          . '&rname='
          . uri_escape( $_->{external_id}, "^A-Za-z0-9" )
          . '&myAction=edit&furl='
          . $safeUrl
          . '\';" /></td>' . '</tr>';
    }

    $psgi_out .= <<END_HERE;
    </table>
    <table border="0" cellspacing="4" cellpadding="2">
      <tr>
	<td align="left" style="width:400px;">
	<input type="button" value="Last ${rubricsPerPage} Rubrics" onClick="document.form1.step.value -= 2 * ${rubricsPerPage}; document.form1.submit();" />&nbsp;&nbsp;&nbsp;
	<input type="button" value="Next ${rubricsPerPage} Rubrics" onClick="document.form1.submit();" /></td>
      </tr>
    </table>
		<br />
    <table border="1" cellspacing="0" cellpadding="2">
    <tr><td>
      <table border="0" cellspacing="3" cellpadding="3">
        <tr>
	  <td><span class="text">Rename:</td>
	  <td><input type="text" size="25" name="newRubricName" /></td>
	  <td><input type="button" style="width:130px;" value="Rename Selected" onClick="renameRubric();" /></td>
	</tr>
      </table>
    </td></tr>
    </table> 
    </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}
1;
