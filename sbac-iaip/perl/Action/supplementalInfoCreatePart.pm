package Action::supplementalInfoCreatePart;

use URI;
use URI::Escape;
use ItemConstants;
use SupplementalInfoConstants;
use HTTP::Date;
use Data::Dumper;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $sql;
  our $sth;
  
  # if no supplemental info is supplied, error out 
  
  unless(exists $in{supplementalInfoId}) {
  
    return [ $q->psgi_header('text/html'), [ &html_die('Unable to find Supplemental Info request.') ]];
  }
  
  $in{supplementalInfoPartId} = '' unless exists $in{supplementalInfoPartId};
  $in{myAction} = '' unless exists $in{myAction};
  
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
             [ &html_die('Unable to create Supplemental Info Part request.') ]];
  }
  
  my $paramsFile  = "${orcaPath}workflow/supplemental-info/$in{supplementalInfoId}/main.cfg";
  my $params = &get_params($paramsFile);
  my $part_params = {};
  
  if($in{supplementalInfoPartId} ne '') {
  
    my $partFile  = "${orcaPath}workflow/supplemental-info/$in{supplementalInfoId}/$in{supplementalInfoPartId}.cfg";
    $part_params = &get_params($partFile);
  }
  
  if ( $in{myAction} eq 'save' ) {
  
    my $rec_id = ($in{supplementalInfoPartId} ne '')
                 ? $in{supplementalInfoPartId}
  	       : &create_supplemental_info_part($in{supplementalInfoId});
  
    return [ $q->psgi_header('text/html'), 
             [ &html_die('Unable to create Supplemental Info Part request.') ]] unless $rec_id;
  
    my $partFile  = "${orcaPath}workflow/supplemental-info/$in{supplementalInfoId}/${rec_id}.cfg";
  
    $in{supplementalInfoPartId} = $rec_id;
  
    foreach my $key (@requestPartFieldList) {
      $part_params->{$key} = $in{$key} if defined $in{$key}; 
    }
  
    &set_params($partFile,$part_params);
  }
  
  my $workTypeLabel = $workTypes{$workType};
  my $objectTypeLabel = $objectTypes{$objectType};
  
  my $psgi_out = <<HTML;
  <!DOCTYPE html>
  <html>
    <head>
      <meta http-equiv="x-ua-compatible" content="IE=9" />
      <title>${workTypeLabel} Request for ${objectTypeLabel} '$params->{name}' Part</title>
      <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
      <script type="text/javascript">
  
        function doSave() {
  
          document.editForm.submit();
        }
  
        function doClose() {
          window.opener.document.editForm.submit();
  	self.close();
        }
  
        function getImageUrl(valueField) {
          window.open('${orcaUrl}cgi-bin/getItemGraphicUrl.pl?itemId=${objectId}&valueField=' + valueField,'graphicWin','directories=no,toolbar=no,status=no,scrollbars=yes,resizable=yes,width=400,height=600');
        }
  
        function viewMedia(mediaName) {
          window.open('${orcaUrl}blank.html','mediaWin','directories=no,toolbar=no,status=no,scrollbars=yes,resizable=yes,width=500,height=300');
  	document.mediaForm.target='mediaWin';
  	document.mediaForm.imageId.value=mediaName;
  	document.mediaForm.submit();
  
        }
  
        function selectMedia() {
          document.editForm.submit();
        }
  
  
      </script>
    </head>
    <body>
      <div class="title">${workTypeLabel} Request for ${objectTypeLabel} '$params->{name}' Part</div>
      <table border="0" cellpadding="2" cellspacing="2" class="no-style">
HTML
  
  foreach my $field (@requestFieldList) {
  
    my $fieldDisplayHtml = $params->{$field};
    my $fieldType = $fieldDefinition{$field}{type};
  
    if($fieldType eq 'list') {
      $fieldDisplayHtml = $fieldDefinition{$field}{valueMap}->{$params->{$field}};
    } elsif($fieldType eq 'assignee') {
      $fieldDisplayHtml = $users->{$params->{$field}};
    }
  
    $psgi_out .= <<HTML;
    <tr>
      <td>$fieldDefinition{$field}{label}:</td>
      <td>${fieldDisplayHtml}</td>
    </tr>
HTML
  }
  
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
  
  $psgi_out .= <<HTML;
     </table>
     <br />
      <form name="mediaForm" action="${orcaUrl}cgi-bin/mediaView.pl">
        <input type="hidden" name="itemBankId" value="${itemBankId}" />
        <input type="hidden" name="itemName" value="${itemName}" />
        <input type="hidden" name="version" value="${version}" />
        <input type="hidden" name="imageId" value="" />
      </form>
      <form name="editForm" action="${orcaUrl}cgi-bin/supplementalInfoCreatePart.pl" method="POST">
        <input type="hidden" name="supplementalInfoId" value="$in{supplementalInfoId}" />
        <input type="hidden" name="supplementalInfoPartId" value="$in{supplementalInfoPartId}" />
        
        <input type="hidden" name="myAction" value="save" />
     <br />
     <p>${workTypeLabel} Specifications:</p>
      <table border="0" cellpadding="2" cellspacing="2" class="no-style">
HTML
  
  foreach my $field (@requestPartFieldList) {
  
    my $fieldDisplayHtml = '';
    my $fieldType = $fieldDefinition{$field}{type};
  
    if($fieldType eq 'readonly') {
      $fieldDisplayHtml = $part_params->{$field};
    } elsif($fieldType eq 'string') {
      $fieldDisplayHtml = '<input type="text" name="' . $field . '" value="' . $part_params->{$field} . '"'
                        . ( exists($fieldDefinition{$field}{size}) ? ' size="' . $fieldDefinition{$field}{size} . '"' : '' )
                        . '/>';
    } elsif($fieldType eq 'list') {
      $fieldDisplayHtml = &hashToSelect($field,$fieldDefinition{$field}{valueMap},$part_params->{$field});
    } elsif($fieldType eq 'graphic') {
      
      if(defined $part_params->{$field} && $part_params->{$field} ne '') {
  
        if($part_params->{$field} =~ /\.svg$/) {
  
          $fieldDisplayHtml .= '<object data="' . $part_params->{$field} . '" type="image/svg+xml" wmode="transparent"></object>';
        } else {
  
          $fieldDisplayHtml .= '<img src="' . $part_params->{$field} . '" border="0" />'
        }
  
        $fieldDisplayHtml .= '<input type="hidden" name="' . $field . '" value="' . $part_params->{$field} . '" />'
                          . '&nbsp;&nbsp;';
      } else {
        $fieldDisplayHtml = '<input type="hidden" name="' . $field . '" value="" />';
      }
      
      $fieldDisplayHtml .= '<input type="button" value="Select" onClick="getImageUrl(\'' . $field . '\');" />';
  
    } elsif($fieldType eq 'media') {
      
      if(defined $part_params->{$field} && $part_params->{$field} ne '') {
  
        $fieldDisplayHtml .= '<a href="#" onClick="viewMedia(\'' . $part_params->{$field} . '\');">' 
                           . 'View</a>&nbsp;&nbsp;'
  
        #$fieldDisplayHtml .= '<input type="hidden" name="' . $field . '" value="' . $part_params->{$field} . '" />'
        #                  . '&nbsp;&nbsp;';
      } else {
        #$fieldDisplayHtml = '<input type="hidden" name="' . $field . '" value="" />';
      }
  
      my $list = {};
  
      if($objectType == $OT_ITEM) {
        $list = &getItemMediaList();
      }
  
      if(scalar keys %$list) {
      
        $fieldDisplayHtml .= &hashToSelect($field, $list, $part_params->{$field}, 'selectMedia();');
      } else {
        $fieldDisplayHtml .= '<input type="hidden" name="' . $field . '" value="" />'
                          . 'None Available';
        
      }
  
    } else {
      $fieldDisplayHtml = '&nbsp;';
    }
  
    $psgi_out .= <<HTML;
    <tr>
      <td>$fieldDefinition{$field}{label}:</td>
      <td style="vertical-align:middle;">${fieldDisplayHtml}</td>
    </tr>
HTML
  }
  
  
  $psgi_out .= <<HTML;
     </table>
     <br />
     <input type="button" value="Save" onClick="doSave();" />
     </form>
     <br />
      <p><input type="button" value="Close" onClick="doClose();" /></p>
    </body>
  </html>  
HTML

  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
}

# DONE!

sub create_supplemental_info_part {

  my $supplementalInfoId = shift;

  return 0 unless $supplementalInfoId;
 
  $sql = <<SQL;
  INSERT INTO work_supplemental_info_part 
    SET wsi_id=${supplementalInfoId} 
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

sub getItemMediaList {

  my %list = ();

  my $sql = <<SQL;
  SELECT * FROM item_asset_attribute
    WHERE i_id=${objectId}
      AND iaa_filename REGEXP "\.mp3\$|\.m4a|\.m4v\$|\.mp4|\.swf\$"
SQL

  my $sth = $dbh->prepare($sql);
  $sth->execute();

  while(my $row = $sth->fetchrow_hashref) {
    next if $row->{iaa_filename} eq '';
    $list{$row->{iaa_filename}} = $row->{iaa_filename};
  }
  $sth->finish;

  return \%list;
}
1;
