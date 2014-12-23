package Action::passagePrintList;

use ItemConstants;
use Item;
use Passage;
use Rubric;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $this_url = "${orcaUrl}cgi-bin/passagePrintList.pl";
  
  our $autoPrint = $in{autoPrint} || 0;
  
  our %viewTypes = (
      '1' => 'Teacher View',
      '2' => 'Copy View',
      '8' => 'Custom View'
  );
  
  our $customKey = '8';
  
  our %viewFields = (
      '1' => [
           'gle',
          'itemId',         'itemDescription',
          'itemContent',    'distractorRationale', 'correctResponse',
          'itemMetadata',   'itemRubric'
      ],
      '2' => [
          'gle',                 'itemId',
          'itemDescription',     'itemContent',
          'distractorRationale', 'correctResponse', 'itemMetadata',
          'rejectReason',        'itemRubric'
      ],
  );
  
  our %itemMetaFields = (
      '1' => [
          'gradeLevel', 
          'itemDOK',    'itemDifficulty',
      ],
      '2' => [
          'itemFormat',       'contentArea',
          'gradeLevel', 
          'itemDOK',        'devState',
          'itemDifficulty', 
      ],
  );
  
  our @totalViewFields = (
            'gle',
      'itemId',              'itemDescription',
      'itemContent',         'uploadFields',
      'distractorRationale', 'correctResponse', 'itemMetadata',
      'rejectReason',        'itemRubric',
      'imsInfo',             'oibInfo',
      'usageInfo',           'itemNotes',
      'itemPassage'
  );
  
  our @totalMetaFields = (
      'itemFormat',             'contentArea',
      'gradeLevel',          
      'itemDOK',              'devState',
      'itemDifficulty',       
      'defaultResponse',      'primaryContentCode',
      'secondaryContentCode', 'tertiaryContentCode',
      'imsId',                'calculator',
      'sourceDoc',            'compCurriculum',
      'publicationStatus'
  );
  
  our %fieldDescriptions = (
      'gle'                  => 'GLE',
      'itemId'               => 'Item name',
      'itemDescription'      => 'Description',
      'itemContent',         => 'Content',
      'distractorRationale', => 'Distractor Rationale',
      'itemMetadata'         => 'Metadata',
      'rejectReason'         => 'Client Reject Reason',
      'itemRubric'           => 'Rubric',
      'itemPassage'          => 'Passage',
      'itemFormat'             => 'Format',
      'contentArea'          => 'Content Area',
      'gradeLevel'           => 'Grade Level',
      'itemDOK'              => 'DOK',
      'devState'             => 'Dev State',
      'itemDifficulty'       => 'Difficulty',
      'correctResponse'      => 'Correct Answer',
      'defaultResponse'      => 'Default Answer',
      'primaryContentCode'   => 'Primary Content Code',
      'secondaryContentCode' => 'Secondary Content Code',
      'tertiaryContentCode'  => 'Tertiary Content Code',
      'sourceDoc'            => 'Source Documentation',
      'compCurriculum'       => 'Comp. Curriculum',
      'imsInfo'              => 'IMS Info',
      'oibInfo'              => 'OIB Info',
      'usageInfo'            => 'Usage Info',
      'itemNotes'            => 'Item Notes',
      'imsId'                => 'IMS ID',
      'calculator'           => 'Calculator',
      'publicationStatus'    => 'Publication Status'
  );
  
  our %uploadFields  = ();
  our @uploadHeaders = ();
  
  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{myAction}  = '' unless exists $in{myAction};
  $in{passageId} = '' unless exists $in{passageId};
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  our @itemIds = ();
  
  # Save the form inputs, since the item loop clears the %in hash
  our $itemBank = $in{itemBankId};
  our $viewType = $in{viewType} || '2';
   
  return [ $q->psgi_header('text/html'), [ &printPassage() ]]; 
}

### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    my $params = shift;

    my $contentArea =
      exists( $params->{contentArea} ) ? $params->{contentArea} : '';
    my $gradeLevel =
      exists( $params->{gradeLevel} ) ? $params->{gradeLevel} : '';

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $defaultBank = (
        defined $params->{itemBankId}
        ? $params->{itemBankId}
        : ( keys %$banks )[0] );
    my $omitRejectedItems =
      defined( $params->{omitRejectedItems} ) ? 'CHECKED' : '';
    my $ibankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $defaultBank, 'reloadForm();',
        '' );
    my $viewDisplay =
      &hashToSelect( 'viewType', \%viewTypes,
        exists( $params->{viewType} ) ? $params->{viewType} : '',
        'reloadForm();' );
    my $contentAreaDisplay =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        $contentArea, 'reloadForm();', 'null', 'value' );
    my $gradeLevelDisplay =
      &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], $gradeLevel,
        'reloadForm();', 'null', 'value' );
    my $passageDisplay =
      &hashToCheckbox( 'passageId',
        &getPassageList( $dbh, $defaultBank, $contentArea, $gradeLevel ),
        1, 'value' );

    $psgi_out = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Passage Print Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
    <script language="JavaScript">

      function doSubmit(f, btn) {
		if(btn == 'file' && ! f.myfile.value.match(/\\.csv\$/i) ) {
			alert('Invalid Filetype, must be CSV.');
			f.myfile.focus();
			return false;
		}
			  f.target = '_blank';
			  f.myAction.value = 'print';
			f.submit();
	}	

			function getItemXml() {
			  document.itemView.target = '_self';
				document.itemView.myAction.value = 'getItemXml';
				document.itemView.submit();
			}

      function reloadForm() {
			  document.itemView.target = '_self';
				document.itemView.myAction.value = '';
			  document.itemView.submit();
			}	
      	function checkMetadataCBX(f) {
		f.view_itemMetadata.checked = false;
		var ff = f.elements;
		for(i=0;i<ff.length;i++) {
		    if(ff[i].name.match(/^meta_/)) {
			if(ff[i].checked) f.view_itemMetadata.checked = true;
		    }
		}
	}

		</script>
	</head>
  <body>
    <div class="title">Passage Print Viewer</div>
    <form name="itemView" action="${this_url}" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="myAction" value="" />
     
    <table border="0" cellspacing="4" cellpadding="3" class="no-style">
      <tr><td><span class="text">View Format:</span></td><td>${viewDisplay}</td></tr>
    </table>
		<br />
    <table border="0" cellspacing="4" cellpadding="3" class="no-style">
END_HERE

    if ( $params->{viewType} eq $customKey ) {

        $in{view_itemRubric} = 1;

        $psgi_out .=
'<tr><td width="160"><span class="text">Custom View:</span></td><td>&nbsp;</td></tr>'
          . '<tr><td><b>Fields</b></td><td><b>Metadata</b></td></tr>'
          . '<tr><td style="text-align:left;vertical-align:top;">';

        foreach ( grep { !/uploadFields/ } @totalViewFields ) {
            $psgi_out .= '<input type="checkbox" name="view_' 
              . $_ . '" '
              . ( exists $in{"view_$_"} ? 'CHECKED' : '' )
              . ' />&nbsp;'
              . $fieldDescriptions{$_}
              . '<br />';
        }

        $psgi_out .= '</td><td style="text-align:left;vertical-align:top;">';

        foreach (@totalMetaFields) {
            $psgi_out .= '<input type="checkbox" name="meta_' 
              . $_ . '" '
              . ( exists $in{"meta_$_"} ? 'CHECKED' : '' )
              . ' onClick="checkMetadataCBX(this.form)" />&nbsp;'
              . $fieldDescriptions{$_}
              . '<br />';
        }
        $psgi_out .= '</td></tr>'
          . '<tr><td colspan="2"><input type="checkbox" value="1" name="doFieldUpload" />&nbsp;Upload custom data fields?'
          . '</td></tr><tr><td colspan="2">&nbsp;</td></tr>';
    }

    $psgi_out .= <<END_HERE;
      	<tr><td><span class="text">Program:</span></td><td>${ibankDisplay}</td></tr>
	<tr><td><span class="text">Enter Single Passage ID:</span></td><td><input type="text" name="p_name" /></td></tr> 
	<tr><td>&nbsp;</td><td><input type="button" value="Show Print View" onClick="doSubmit(this.form, 'id');" /> </td> </tr>
      	<tr><td colspan="2"><b>Select Passage From File</b></td></tr> 
	<tr><td><span class="text">Upload File:</span></td><td><input type="file" name="myfile" /></td></tr> 
	<tr><td>&nbsp;</td><td><input type="button" value="Show Print View" onClick="doSubmit(this.form, 'file');" /> </td> </tr>
END_HERE


    $psgi_out .= <<END_HERE;
        </td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}


sub printPassage {
  my $psgi_out = '';

    my %passages;
    my @passage = ();
    my $cnt   = 0;
    if( $in{p_name} ) {
	$in{p_name} =~ s/'/\\'/g;
	push @passage, $in{p_name};
    }
    elsif ( $in{myfile} ) {
	my $uploadHandle = $q->upload("myfile");
    	while (<$uploadHandle>) {
	    s/\s+$//g;
	    s/'/\\'/g;
	    push @passage, $_;
    	}
    }

    my $sql = sprintf qq|SELECT p.*, oc.oc_int_value AS content_area FROM passage p 
			 JOIN object_characterization oc ON oc.oc_object_id = p.p_id 
			 AND oc.oc_object_type = %s AND oc.oc_characteristic = %s
			 WHERE p.ib_id = %d AND p.p_name IN ('%s')
			|, $OT_PASSAGE, $OC_CONTENT_AREA, $itemBank, join("','", @passage);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while(my $row = $sth->fetchrow_hashref ) {
	$row->{p_name} =~ s/'/\\'/g;
	$row->{content_area} = $const[$OC_CONTENT_AREA]->{$row->{content_area}};
        $passages{"$row->{p_name}"} = $row;
	$cnt++;
    }
    $sth->finish;

    if( $cnt > 0  ) {
    	for ( map { $passages{"$_"} } @passage ) {
	    $_->{p_name} =~ s/\\//g;
	    $psgi_out .= "<p>Passage name : <i>$_->{p_name}</i><br/>";
	    $psgi_out .= "Subject : <i>$_->{content_area}</i></p>";
	    local *HTML;
	    open HTML, "< /www/$_->{p_url}" or warn "Error opening Passage:$!";
       	    $psgi_out .= <HTML>;
	    close HTML;
	    $psgi_out .= "<hr/>";
	}
    }
    else {
	$psgi_out .= qq|<font size="4" color="red">No Passage(s) found in this Item Bank!|;
    }
  return $psgi_out;
}
1;
