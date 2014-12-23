package Action::supplementalInfoCreate;

use URI;
use URI::Escape;
use ItemConstants;
use SupplementalInfoConstants;
use Item;
use HTTP::Date;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $sql;
  our $sth;
  
  # if no supplemental info ID is supplied, assume user it creating a new one
  
  unless(exists $in{supplementalInfoId}) {
  
    my $rec_id = &create_or_edit_supplemental_info($in{itemBankId} || 0, $in{objectType} || 0, $in{objectId} || 0, $in{workType} || 0);
  
    return [ $q->psgi_header('text/html') ,
             [ &html_die('Unable to create Supplemental Info request.') ]] unless $rec_id;
  
    $in{supplementalInfoId} = $rec_id;
  
    my $work_dir = "${orcaPath}workflow/supplemental-info/$in{supplementalInfoId}";
  
    unless(-e $work_dir) {
      mkdir $work_dir, 0775;
    }
  }
  
  our $workType = 0;
  our $objectType = 0;
  our $objectId = 0;
  our $itemBankId = 0;
  our @requestFieldList = ();
  our @requestPartFieldList = ();
  our $users = {};
  
  $sql = 'SELECT * FROM work_supplemental_info WHERE wsi_id=' . $in{supplementalInfoId};
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  if(my $row = $sth->fetchrow_hashref) {
  
    $itemBankId = $row->{ib_id};
    $workType = $row->{wsi_work_type};
    $objectType = $row->{wsi_object_type};
    $objectId = $row->{wsi_object_id};
  
    @requestFieldList = @{$requestField{$workType}};
    @requestPartFieldList = @{$requestPartField{$workType}};
  
    $users = &getUsersWithReviewType($dbh, $workAssigneeTypes{$workType}, $itemBankId);
  
  } else {
    return [ $q->psgi_header('text/html'), 
             [ &html_die("Unable to find workflow record $in{supplementalInfoId}") ]];
  }
  $sth->finish;
  
  my $passage;
  my $item;
  
  if($objectType == $OT_ITEM) {
    $item = new Item($dbh, $objectId);
  } elsif($objectType == $OT_PASSAGE) {
    $passage = new Passage($dbh, $objectId);
  }
  
  my $paramsFile  = "${orcaPath}workflow/supplemental-info/$in{supplementalInfoId}/main.cfg";
  my $params = &get_params($paramsFile);
  
  if ( $in{myAction} eq 'save' ) {
  
    foreach my $key (@requestFieldList) {
      $params->{$key} = $in{$key} if defined $in{$key}; 
  
      if($fieldDefinition{$key}{type} eq 'assignee') {
        if($in{$key} ne '') {
  
          $sql = "UPDATE work_supplemental_info SET wsi_u_id=$in{$key} WHERE wsi_id=$in{supplementalInfoId}";
          $sth = $dbh->prepare($sql);
          $sth->execute();
  	$sth->finish;
        }
      }
    }
  
  
  
  } elsif ( $in{myAction} eq 'removePart') {
  
    $sql = 'DELETE FROM work_supplemental_info_part WHERE wsip_id=' . $in{partId};
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    unlink "${orcaPath}/workflow/supplemental-info/$in{supplementalInfoId}/$in{partId}.cfg";
  }
  
  foreach my $field (grep { $fieldDefinition{$_}{type} eq 'readonly' } @requestFieldList) {
  
    my $value;
  
    if($objectType == $OT_ITEM) {
  
      $value = $item->{$fieldDefinition{$field}{value}};
  
    } elsif($objectType == $OT_PASSAGE) {
  
      if($field eq 'gradeLevel') {
    
        $value = $passage->{gradeLevel};
  
      } elsif($field eq 'contentArea') {
  
        $value = $passage->{contentArea};
      } else {
  
        $value = $passage->{$fieldDefinition{$field}{value}};
      }
    }
    
    $params->{$field} = (exists $fieldDefinition{$field}{valueMap})
                      ? $fieldDefinition{$field}{valueMap}->{$value}
  		    : $value;
  }
  
  # update our values
  &set_params($paramsFile,$params);
  
  my %part_params = ();
  
  $sql = 'SELECT * FROM work_supplemental_info_part WHERE wsi_id=' . $in{supplementalInfoId};
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  while(my $row = $sth->fetchrow_hashref) {
  
    my $index = $row->{wsip_id};
    my $partFile  = "${orcaPath}workflow/supplemental-info/$in{supplementalInfoId}/${index}.cfg";
  
    $part_params{$index} = &get_params($partFile);
  
  }
  $sth->finish;
  
  
  my $workTypeLabel = $workTypes{$workType};
  my $objectTypeLabel = $objectTypes{$objectType};
  
  my $itemName = '';
  my $version = 0;
  my $imageId = '';
  
  if($objectType == $OT_ITEM) {
  
    my $sql = 'SELECT i_external_id, i_version FROM item WHERE i_id=' . $objectId;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
  
    if(my $row = $sth->fetchrow_hashref) {
      $itemName = $row->{i_external_id};
      $version = $row->{i_version};
    }
  }
  
  my $psgi_out = <<HTML;
  <!DOCTYPE html>
  <html>
    <head>
      <meta http-equiv="x-ua-compatible" content="IE=9" />
      <title>${workTypeLabel} Request for ${objectTypeLabel} '$params->{name}'</title>
      <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
      <script src="${commonUrl}js/calendar/cal2.js" type="text/javascript"></script>
      <script type="text/javascript">
  
HTML
  foreach my $field ( grep { $fieldDefinition{$_}{type} eq 'date' } @requestFieldList) {
    $psgi_out .= <<HTML;
      addCalendar("calendar_${field}", "Select Date", "${field}", "editForm");
      setWidth(90, 1, 15, 1);
      setFormat("yyyy-mm-dd");
HTML
  }
  
  $psgi_out .= <<HTML;
  
        function addPart() {
  
          document.addPartForm.submit();
        }
  
        function removePart(id) {
  
          document.editForm.partId.value = id;
  	document.editForm.myAction.value = 'removePart';
  	document.editForm.submit();
        }
  
        function editPart(id) {
  
          document.addPartForm.supplementalInfoPartId.value = id;
  	document.addPartForm.submit();
        }
  
        function doSave() {
  
          document.editForm.submit();
        }
  
        function viewMedia(mediaName) {
          window.open('${orcaUrl}blank.html','mediaWin','directories=no,toolbar=no,status=no,scrollbars=yes,resizable=yes,width=500,height=300');
  	document.mediaForm.target='mediaWin';
  	document.mediaForm.imageId.value=mediaName;
  	document.mediaForm.submit();
  
        }
  
      </script>
    </head>
    <body>
      <div class="title">${workTypeLabel} Request for ${objectTypeLabel} '$params->{name}'</div>
      <form name="addPartForm" action="${orcaUrl}cgi-bin/supplementalInfoCreatePart.pl" method="POST" target="_blank">
        <input type="hidden" name="supplementalInfoId" value="$in{supplementalInfoId}" />
        <input type="hidden" name="supplementalInfoPartId" value="" />
        
      </form>
      <form name="mediaForm" action="${orcaUrl}cgi-bin/mediaView.pl">
        <input type="hidden" name="itemBankId" value="${itemBankId}" />
        <input type="hidden" name="itemName" value="${itemName}" />
        <input type="hidden" name="version" value="${version}" />
        <input type="hidden" name="imageId" value="" />
      </form>
      <form name="editForm" action="${orcaUrl}cgi-bin/supplementalInfoCreate.pl" method="POST">
        <input type="hidden" name="supplementalInfoId" value="$in{supplementalInfoId}" />
        
        <input type="hidden" name="partId" value="" />
        <input type="hidden" name="myAction" value="save" />
      <table border="0" cellpadding="2" cellspacing="2" class="no-style">
HTML
  
  foreach my $field (@requestFieldList) {
  
    my $fieldDisplayHtml = '';
    my $fieldType = $fieldDefinition{$field}{type};
  
    if($fieldType eq 'readonly') {
      $fieldDisplayHtml = $params->{$field};
    } elsif($fieldType eq 'generated') {
  
      my $value = '';
      if(defined $params->{$field}) {
        $value = $params->{$field};
      } else {
        $value = $fieldDefinition{$field}{generator}->();  
      }
  
      $fieldDisplayHtml = $value
                       . ' <input type="hidden" name="' . $field . '" value="' . $value . '" />';
  
    } elsif($fieldType eq 'string') {
      $fieldDisplayHtml = '<input type="text" name="' . $field . '" value="' . $params->{$field} . '"'
                        . ( exists($fieldDefinition{$field}{size}) ? ' size="' . $fieldDefinition{$field}{size} . '"' : '' )
  		      . ' />';
    } elsif($fieldType eq 'list') {
      $fieldDisplayHtml = &hashToSelect($field,$fieldDefinition{$field}{valueMap},$params->{$field});
    } elsif($fieldType eq 'date') {
      $fieldDisplayHtml = <<HTML;
      <input type="text" id="${field}" name="${field}" size="11" value="$params->{$field}" />
      &nbsp;<a href="#" onClick="showCal('calendar_${field}')">Select Date</a>
      <div id="calendar_${field}"></div>
HTML
    } elsif($fieldType eq 'assignee') {
      $fieldDisplayHtml = &hashToSelect($field,$users,$params->{$field});
    } else {
      $fieldDisplayHtml = '&nbsp;';
    }
  
    $psgi_out .= <<HTML;
    <tr>
      <td>$fieldDefinition{$field}{label}:</td>
      <td>${fieldDisplayHtml}</td>
    </tr>
HTML
  }
  
  
  $psgi_out .= <<HTML;
     </table>
     <br />
     <input type="button" value="Save" onClick="doSave();" />
     </form>
     <br />
     <p>${workTypeLabel} Specifications:</p>
HTML
  
  if(scalar keys %part_params) {
  
    $psgi_out .= '<table border="1" cellspacing="2" cellpadding="2" class="no-style">';
  
    $psgi_out .= '<tr>';
  
    foreach my $field (@requestPartFieldList) {
  
        $psgi_out .= '<th>' . $fieldDefinition{$field}{label} . '</th>';
    }
  
  
    $psgi_out .= '<th>Edit</th><th>Remove</th></tr>';
  
    foreach my $index (keys %part_params) {
      
      $psgi_out .= '<tr>';
  
      foreach my $field (@requestPartFieldList) {
  
        my $fieldDisplayHtml = '';
        my $fieldType = $fieldDefinition{$field}{type};
  
        if($fieldType eq 'readonly' or $fieldType eq 'string') {
          $fieldDisplayHtml = $part_params{$index}{$field};
        } elsif($fieldType eq 'list') {
          $fieldDisplayHtml = $fieldDefinition{$field}{valueMap}->{$part_params{$index}{$field}};
        } elsif($fieldType eq 'graphic') {
  
          if($part_params{$index}{$field} eq '') {
  	  $fieldDisplayHtml = '&nbsp;';
          } elsif($part_params{$index}{$field} =~ /\.svg$/) {
            $fieldDisplayHtml = '<object data="' . $part_params{$index}{$field} . '" type="image/svg+xml"  wmode="transparent"></object>';
  	} else {
            $fieldDisplayHtml = '<img src="' . $part_params{$index}{$field} . '" border="0" />';
  	}
        } elsif($fieldType eq 'media') {
      
          if(defined $part_params{$index}{$field} && $part_params{$index}{$field} ne '') {
  
            $fieldDisplayHtml .= '<a href="#" onClick="viewMedia(\'' . $part_params{$index}{$field} . '\');">' 
                               . 'View</a>&nbsp;&nbsp;'
  
          } else {
            $fieldDisplayHtml = '&nbsp;';
          } 
        }
  
        $psgi_out .= '<td>' . $fieldDisplayHtml . '</td>';
      }
  
      $psgi_out .= <<HTML;
      <td>
        <input type="button" name="remove" value="Edit" onClick="editPart('${index}');" />
      </td>
      <td>
        <input type="button" name="remove" value="Remove" onClick="removePart('${index}');" />
      </td>
HTML
  
      $psgi_out .= '</tr>';
    }
  
    $psgi_out .= <<HTML;
    </table>
HTML
  
  } else {
    $psgi_out .= '<p>No Specifications Defined</p>';
  }
  
  $psgi_out .= <<HTML;
    <br />
    <input type="button" value="Add ${workTypeLabel}" onClick="addPart();" />
    <br />
HTML
 
  my $notes = {};
  if($objectType == $OT_ITEM) {
    $notes = $item->getAllNotes();
  } elsif( $objectType == $OT_PASSAGE) {
    $notes = $passage->getAllNotes();
  }
  
  if(scalar keys %{$notes}) {
  
    $psgi_out .= <<HTML;
    <br />
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">
  		<tr>
  		  <td colspan="2">
  			Design Notes:<br />
  			<table border="1" cellspacing="2" cellpadding="0" class="no-style">
  			  <tr><th>Name</th><th>Date</th><th>Comment</th></tr>
HTML
  
    foreach my $tstamp (
            grep { exists $workStates{$workType}{$notes->{$_}{devStateValue}} || 
  	         exists $workStates{$workType}{$notes->{$_}{newDevStateValue}} }
            keys %{$notes}
           ) {
  
     my $user =
             $notes->{$tstamp}{lastName} . ', '
                . $notes->{$tstamp}{firstName};
     my $comment = $notes->{$tstamp}{notes};
  
     $psgi_out .= <<HTML;
  		   <tr>
  			   <td>${user}</td>
  				 <td>${tstamp}</td>
  				 <td><span style="width:400px;">${comment}</span></td>
         </tr>
HTML
    }
  
    $psgi_out .= '</table>';
  }
  
  $psgi_out .= <<HTML;
      <p><input type="button" value="Close" onClick="window.close();" /></p>
    </body>
  </html>  
HTML
 
  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
}
# DONE!

sub create_or_edit_supplemental_info {

  my $itemBankId = shift;
  my $objectType = shift;
  my $objectId = shift;
  my $workType = shift;

  return 0 unless $itemBankId && $objectType && $objectId && $workType;

  # look for existing ID and return it

  $sql = <<SQL;
  SELECT wsi_id FROM work_supplemental_info 
    WHERE ib_id=${itemBankId}
      AND wsi_object_type=${objectType}
      AND wsi_object_id=${objectId}
      AND wsi_work_type=${workType}
SQL
  $sth = $dbh->prepare($sql);
  $sth->execute();

  if(my $row = $sth->fetchrow_hashref) {
    $sth->finish;
    return $row->{wsi_id};
  }

  # create a new one if not found
 
  $sql = <<SQL;
  INSERT INTO work_supplemental_info 
    SET ib_id=${itemBankId}, wsi_object_type=${objectType}, wsi_object_id=${objectId}, wsi_work_type=${workType} 
SQL
  $sth = $dbh->prepare($sql);
  $sth->execute();

  my $rec_id = $dbh->{mysql_insertid};
  $sth->finish;

  return $rec_id;
}

sub html_die {

  my $msg = shift;

  return <<HTML;
  <html>
    <head>
    </head>
    <body>
      <h3>Action Failed</h3>
      <p>$msg</p>
    </body>
  </html>
HTML
}
1;
