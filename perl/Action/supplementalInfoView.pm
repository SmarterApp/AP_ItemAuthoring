package Action::supplementalInfoView;

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
      <script type="text/javascript">
  
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
      <form name="mediaForm" action="${orcaUrl}cgi-bin/mediaView.pl">
        <input type="hidden" name="itemBankId" value="${itemBankId}" />
        <input type="hidden" name="itemName" value="${itemName}" />
        <input type="hidden" name="version" value="${version}" />
        <input type="hidden" name="imageId" value="" />
      </form>
      <table border="0" cellpadding="2" cellspacing="2" class="no-style">
HTML
  
  foreach my $field (@requestFieldList) {
  
    my $fieldDisplayHtml = $params->{$field};
    my $fieldType = $fieldDefinition{$field}{type};
  
    if($fieldType eq 'list') {
      $fieldDisplayHtml = $fieldDefinition{$field}{valueMap}->{$params->{$field}}
        if exists $fieldDefinition{$field}{valueMap}->{$params->{$field}};
    } elsif($fieldType eq 'assignee') {
      $fieldDisplayHtml = $users->{$params->{$field}} if exists $users->{$params->{$field}};
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
     <p>${workTypeLabel} Specifications:</p>
HTML
  
  if(scalar keys %part_params) {
  
    $psgi_out .= '<table border="1" cellspacing="2" cellpadding="2" class="no-style">';
  
    $psgi_out .= '<tr>';
  
    foreach my $field (@requestPartFieldList) {
  
        $psgi_out .= '<th>' . $fieldDefinition{$field}{label} . '</th>';
    }
  
    $psgi_out .= '</tr>';
  
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
  
        } else {
          $fieldDisplayHtml = '&nbsp;';
        }
  
        $psgi_out .= '<td>' . $fieldDisplayHtml . '</td>';
      }
  
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
HTML
 
  my $notes;
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
