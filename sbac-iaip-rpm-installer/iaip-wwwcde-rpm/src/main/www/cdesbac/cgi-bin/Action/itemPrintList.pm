package Action::itemPrintList;

use ItemConstants;
use Item;
use Passage;
use Rubric;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;

  our $this_url = "${orcaUrl}cgi-bin/itemPrintList.pl";

  our $autoPrint = $in{autoPrint} || 0;

  our %viewTypes = (
    '8' => 'Custom View'
  );

  our $customKey = '8';

  $in{viewType} = $customKey unless $in{viewType};

  our %viewFields = (
    '1' => [
         'gle',
        'itemId',         'itemDescription',
        'itemContent',    'distractorRationale', 'correctResponse',
        'itemMetadata',   'itemRubricContent'
    ],
    # viewType = 2 will provide view for jasper reports
    '2' => [
        'gle',                 'itemId',
        'itemDescription',     'itemContent',
        'distractorRationale',  'correctResponse',
'itemMetadata',
    ],
    '3' => [
              'gle',
        'itemId',              'itemContent',
        'distractorRationale',  'correctResponse',
'itemMetadata',
        'itemRubricContent',          'oibInfo'
    ],
    '4' => [
        'gle',                 'itemId',
        'itemDescription',     'itemContent',
        'distractorRationale',  'correctResponse',
'itemMetadata',
        'itemRubricContent'
    ],
    '5' => [
        'gle',                 'itemId',
        'itemDescription',     'itemContent',
        'distractorRationale',  'correctResponse',
'itemMetadata',
        'itemRubricContent'
    ],
    '6' => [
        'gle',          'itemId',
        'itemContent',  'distractorRationale', 'correctResponse',
        'itemMetadata', 'itemRubricContent'
    ],
    '7' => [
        'gle',          'itemId',
        'itemContent',  'distractorRationale', 'correctResponse',
        'itemMetadata', 'itemRubricContent'
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
	'publicationStatus',
        'itemDifficulty',
	'itemPassage', 'itemRubric',
	'itemMetafiles'
    ],
    '3' => [
        'itemFormat',        'contentArea',
        'gradeLevel',    
        'itemDOK',         'itemDifficulty',
         'primaryContentCode',
        'sourceDoc'
    ],
    '4' => [
        'contentArea', 'gradeLevel',
	'publicationStatus',
        'itemDOK',         'itemDifficulty',
         'sourceDoc'
    ],
    '5' => [
        'gradeLevel', 
        'itemDOK',         'itemDifficulty',
         'sourceDoc'
    ],
    '6' => [
        'imsId',              'gradeLevel',
        'primaryContentCode', 'calculator'
    ],
    '7' => [
        'imsId',              'gradeLevel',
        'primaryContentCode', 'calculator'
    ],
  );

  our @totalViewFields = (
    'itemId',              'itemDescription',
    'itemContent',         'uploadFields',
    'distractorRationale', 'correctResponse', 'itemMetadata',
    'itemPassageContent',
    'itemRubricContent',
    'usageInfo',    'itemNotes',
    'rejectReason', 'copyrightFiles'
  );

  our @totalMetaFields = (
    'itemFormat',
    'devState',
    'itemDifficulty',       
    'itemPassage',
    'itemRubric',
    'calculator',
    'sourceDoc',
    'publicationStatus',
    'editor',
    'enemies',
    'itemMetafiles'
  );

  our %fieldDescriptions = (
    'gle'                  => 'GLE',
    'itemId'               => 'Item ID',
    'itemDescription'      => 'Description',
    'itemContent',         => 'Content',
    'distractorRationale', => 'Distractor Rationale',
    'itemMetadata'         => 'Metadata',
    'rejectReason'         => 'Client Reject Reason',
    'itemRubric'           => 'Rubric',
    'itemRubricContent'           => 'Rubric Content',
    'itemPassage'           => 'Passage',
    'itemPassageContent'          => 'Passage Content',
    'itemFormat'             => 'Format',
    'contentArea'          => 'Content Area',
    'gradeLevel'           => 'Grade Level',
    'itemDOK'              => 'DOK',
    'devState'             => 'Dev State',
    'itemDifficulty'       => 'Difficulty',
    'correctResponse'      => 'Correct Response',
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
    'publicationStatus'    => 'Publication Status',
    'scoring'		   => 'Scoring',
    'editor'		   => 'Editor',
    'enemies'		   => 'Item Enemies',
    'copyrightFiles'       => 'Copyright/DRM Info',
    'itemMetafiles'        => 'Item Metafiles'
  );

  our %uploadFields  = ();
  our @uploadHeaders = ();

  #our $dbh = DBI->connect( $dbDsn, $dbUser, $dbPass );
  our $sth;
  our $sql;

  our $user = Session::getUser($q->env, $dbh); 
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );

  $in{myAction}  = '' unless exists $in{myAction};
  $in{passageId} = '' unless exists $in{passageId};
  if( $in{viewType} eq $customKey ) {
    if( $in{includeRejectedItems} ) { delete $in{omitRejectedItems}; }
    else   { $in{omitRejectedItems} = 1; }
  }

  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];	
  }

  our @itemNameList = ();

  # Save the form inputs, since the item loop clears the %in hash
  our $itemBank = $in{itemBankId} || 0;
  our $viewType = $in{viewType} || '2';

  our @passageIds =
    map { substr( $_, length('passageId') + 1 ) } grep( /^passageId_/, keys %in );
  our %passageMap = ();

  if ( scalar @passageIds ) {

    foreach my $passageId (@passageIds) {

        my @newItemIds = ();

        $sql =
            "SELECT i_id, i_external_id FROM item WHERE i_id IN"
          . " (SELECT i_id FROM item_characterization WHERE ic_type=${OC_PASSAGE} AND ic_value=${passageId})"
          . (
            defined( $in{omitRejectedItems} )
            ? ' AND i_dev_state NOT IN (9)'
            : '' );
        $sth = $dbh->prepare($sql);
        $sth->execute();
        while ( my $row = $sth->fetchrow_hashref ) {
            push @newItemIds, $row->{i_external_id};
        }

        @newItemIds =
          sort { substr( $a, -2 ) <=> substr( $b, -2 ) } @newItemIds;
        $passageMap{$passageId} = $newItemIds[0];

        push @itemNameList, @newItemIds;
    }

  }
  elsif ( $in{myfile} ) {

    my $uploadHandle = $q->upload("myfile");

    open UPLOADED, ">/tmp/itemlist.$$.txt";

    #binmode UPLOADED;
    while (<$uploadHandle>) {
        print UPLOADED;
    }
    close UPLOADED;

    open ITEMLIST, "</tmp/itemlist.$$.txt";

    if ( $in{doFieldUpload} ) {
        my $header = <ITEMLIST>;
        $header =~ s/\s+$//;
        @uploadHeaders = split /,/, $header;
        shift @uploadHeaders;
        %uploadFields = map { $_ => [] } @uploadHeaders;
    }

    while (<ITEMLIST>) {
        $_ =~ s/\s+$//;
        last if $_ eq '';

        next if $_ =~ /^Item/;

        if ( $in{doFieldUpload} ) {
            my @fields = split /,/, $_;
            if ( $_ ne '' ) {
                push( @itemNameList, shift @fields );
                for ( my $i = 0 ; $i < scalar(@fields) ; $i++ ) {
                    push @{ $uploadFields{ $uploadHeaders[$i] } }, $fields[$i];
                }
            }
        }
        else {
            my @fields = split /,/, $_;
            push( @itemNameList, shift @fields ) if $_ ne '';
        }
    }
    close ITEMLIST;

    unlink("/tmp/itemlist.$$.txt");
  }
  elsif ( defined $in{itemExternalId} ) {
    $sql = "SELECT i_id FROM item WHERE i_external_id = '$in{itemExternalId}' and ib_id = $itemBank";
    $sth = $dbh->prepare($sql);
    $sth->execute();
    unless($sth->fetchrow_hashref()) {
      return [ $q->psgi_header('text/html'),
               [ &get_html_header, 
	         &print_no_data( qq|<b>"$in{itemExternalId}"</b> not found in this Item Bank!| ),
		 &get_html_footer ]];
    }
    @itemNameList = split / /, $in{itemExternalId};
  }


  if ( scalar(@passageIds) == 0 && exists $in{view_itemPassageContent} ) {

    # Find any passages associated with the selected items

    foreach my $itemId (@itemNameList) {
        $sql =
        "SELECT ic_value FROM item_characterization WHERE ic_type=${OC_PASSAGE} AND i_id = ("
          . "SELECT i_id FROM item WHERE i_external_id="
          . $dbh->quote($itemId)
          . " AND ib_id=${itemBank} ORDER BY i_version DESC LIMIT 1)";
        $sth = $dbh->prepare($sql);
        $sth->execute();

        while ( my $row = $sth->fetchrow_hashref ) {
            $passageMap{ $row->{ic_value} } = $itemId
              unless exists $passageMap{ $row->{ic_value} };
        }
    }
  }

  our $documentReadyFunction = '';
  our $cssIncludeHeader = '';
  our $html_body = '';

  our %revPassageMap = reverse %passageMap;

  # build viewFields and itemMetaFields
  $viewFields{$customKey}     = [];
  $itemMetaFields{$customKey} = [];

  foreach (@totalViewFields) {
    push( @{ $viewFields{$customKey} }, $_ ) if exists $in{"view_$_"};
    if ( $_ eq 'uploadFields' ) {
        push( @{ $viewFields{$customKey} }, 'uploadFields' )
          if $in{doFieldUpload};
    }
  }

  foreach (@totalMetaFields) {
    push( @{ $itemMetaFields{$customKey} }, $_ ) if exists $in{"meta_$_"};
  }

  our %viewFieldHash = map { $_ => 1 } @{$viewFields{$viewType}};
  our %metaFieldHash = map { $_ => 1 } @{$itemMetaFields{$viewType}};

  if(exists $in{itemId}) {

    $html_body .= &get_item_html( \%in );

  } else {

  for ( my $i = 0 ; $i < scalar(@itemNameList) ; $i++ ) {

    my $itemId = $itemNameList[$i];
    $in{itemSeq} = $i;

    if ( exists $revPassageMap{$itemId} ) {
        my $psg = new Passage( $dbh, $revPassageMap{$itemId} );
        my $psgContent = $psg->getContent();

        if ( $psg->getFootnotesAsString() ne '' ) {
            $psgContent .= '<hr />' . $psg->getFootnotesAsHtml();
        }

        $html_body .= $psgContent . '<br style="page-break-after:always;" />';
    }

    $sql =
        "SELECT * FROM item WHERE i_external_id="
      . $dbh->quote($itemId)
      . " AND ib_id=${itemBank} ORDER BY i_version DESC LIMIT 1";
    $sth = $dbh->prepare($sql);
    $sth->execute();

    my $xml_data = "";
    if ( my $row = $sth->fetchrow_hashref ) {
        next if defined( $in{omitRejectedItems} ) and $row->{i_dev_state} == 9;
        $in{itemId} = $row->{i_id};
    }
    else {
        next;
    }

    $html_body .= &get_item_html( \%in );
  }
  }

  return [ $q->psgi_header('text/html'), [ get_html_header(), $html_body, get_html_footer() ] ];
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
    my $viewDisplay = &hashToSelect( 'viewType', \%viewTypes, 8, 'reloadForm();' );
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

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <title>Item Print Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
    <link href="${orcaUrl}style/footer.css" rel="stylesheet" type="text/css" />
    <script language="JavaScript">

      function doSubmit() {
        document.itemView.target = '_blank';
        document.itemView.myAction.value = 'print';
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
    <div class="title">Item Print Viewer</div>
    <form name="itemView" action="${this_url}" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="myAction" value="" />
     
    <table border="0" cellspacing="4" cellpadding="3" class="no-style">
      <tr><td><span class="text">View Format:</span></td><td>${viewDisplay}</td></tr>
    </table>
		<br />
    <table border="0" cellspacing="4" cellpadding="3" class="no-style">
END_HERE

    if ( $params->{viewType} eq $customKey ) {

        $in{view_itemRubricContent} = 1;

    $psgi_out .= <<END_HERE;
	<tr><td width="160"><span class="text">Custom View:</span></td><td>&nbsp;</td></tr>
        <tr><td><b>Fields</b></td><td><b>Metadata</b></td></tr>
        <tr><td style="text-align:left;vertical-align:top;">
END_HERE

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

    $psgi_out .= qq| <tr><td><span class="text">Program:</span></td><td>${ibankDisplay}</td></tr>|;

    if ( $params->{viewType} eq $customKey ) {
    	$psgi_out .= qq| <tr><td colspan="2"><span class="text">Include Rejected Items:</span>
	    	  <input type="checkbox" name="includeRejectedItems" value="yes" /></td></tr>
		|;
    }
    else {
    	$psgi_out .= qq| <tr><td><span class="text">Omit Items:</span></td>
		       <td><input type="checkbox" name="omitRejectedItems" value="yes" ${omitRejectedItems} /> Rejected</td></tr>
		|;
    }

    $psgi_out .= <<END_HERE;
	<tr><td><span class="text">Enter Single Item ID:</span></td><td><input type="text" name="itemExternalId" /></td></tr> 
	<tr><td>&nbsp;</td><td><input type="button" value="Show Print View" onClick="doSubmit();" /></td></tr>
      	<tr><td colspan="2"><b>Select Items From...</b></td></tr> 
	<tr><td><span class="text">Upload File:</span></td><td><input type="file" name="myfile" /></td></tr> 
	<tr><td>&nbsp;</td><td><input type="button" value="Show Print View" onClick="doSubmit();" /></td></tr>
        <tr><td colspan="2"><b>OR</b></td></tr>
        <tr><td><span class="text">Content Area:</td><td>${contentAreaDisplay}</td></tr>
        <tr><td><span class="text">Grade Level:</td><td>${gradeLevelDisplay}</td></tr>
        <tr><td style="vertical-align:top;"><span class="text">Passage:</td><td style="text-align:left;">${passageDisplay}</td></tr>
        <tr>
        <td>&nbsp;</td>
         <td><input type="button" value="Show Print View" onClick="doSubmit();" />
        </td>
      </tr>
    </table>
    </form>
  </body>
</html>         
END_HERE
}

sub get_item_html {

    my $params = shift;
    my %output = ();

    my $html = '';

    my $item = new Item( $dbh, $params->{itemId} );
    my $c = $item->getDisplayContent(1,1);

    $documentReadyFunction .= $c->{documentReadyFunction} . "\n";
    $cssIncludeHeader .= $item->getCssLink() . "\n";

    my $copyrightFiles = getBankMetafilesForItem($dbh, $item->{id}, $IB_METAFILE_COPYRIGHT);

    my $currentId      = $params->{currentExternalId};
    my $formatName       = $item_formats{ $item->{format} } || '';
    my $difficultyName = $difficulty_levels{ $item->{difficulty} } || '';
    my $devStateName   = $dev_states{ $item->{devState} };

    my $gle = $item->getGLE();
    my $gleName = ( defined $gle->{name} ? $gle->{name} : '' );
    $gleName =~ s/GLE//;
    my $gleText = ( defined $gle->{text} ? $gle->{text} : '' );
    $gleText =~ s/\r?\n/<br \/>/g;

    my $calc = $const[$OC_CALCULATOR]->{ $item->{$OC_CALCULATOR} || 0 };

    $output{itemContent} = <<END_HERE;
    $c->{itemBody}
    <br />
END_HERE

    $output{uploadFields} =
'<table style="font-size:10pt;" border="1" cellspacing="3" cellpadding=2">';

    for ( my $i = 0 ; $i < scalar @uploadHeaders ; $i++ ) {
        $output{uploadFields} .=
            '<tr><td>'
          . $uploadHeaders[$i]
          . '</td><td><b>'
          . $uploadFields{ $uploadHeaders[$i] }->[ $params->{itemSeq} ]
          . '</b></td></tr>';
    }

    $output{uploadFields} .= '</table><br />';

    $output{distractorRationale} = $c->{distractorRationale} . '<br />';

    $output{correctResponse} = $c->{correctResponse} . '<br />';

    if ( $gleName ne '' ) {
        $output{gle} = <<END_HERE;
     <table style="font-size:10pt;" width="650px;" border="1" cellspacing="2" cellpadding="2">
       <tr><th align="center">GLE ${gleName}</th></tr>
       <tr><td>${gleText}</td></tr>
     </table>
     <br />
END_HERE
    }

    $output{rejectReason} = '';
    if ( $item->{rejectReason} ne '' ) {
        $output{rejectReason} = <<END_HERE;
		  <table style="font-size:10pt;" width="400px;" border="1" cellspacing="3" cellpadding="1">
			  <tr><td>Reject Reason:</td>
				    <td>$item->{rejectReason}</td>
				</tr>
			</table>
			<br />
END_HERE
    }

    $output{itemId} =
"Item:&nbsp;&nbsp;<b>$item->{name}</b>&nbsp;&nbsp;&lt;$item->{bankName}&gt;<br />";
    $output{itemDescription} =
      "Description:&nbsp;&nbsp;$item->{description}<br />";

    my $_passages = $item->getPassages;
    if( scalar keys %{$_passages} > 0 ) {
    	$output{passageList} = "Passage: ";
    	foreach( keys %{$_passages} ) {
    	    $output{passageList} .= sprintf qq|<a href="%s" target="_blank">%s</a>%s|, 
					$_passages->{$_}->{url}, $_passages->{$_}->{name}, '&nbsp;&nbsp;';
    	}
	$output{passageList} .= '<br/>';
    }
    else {
	$output{passageList} = '';
    }

    $output{copyrightFiles} = '';
    if(scalar keys %{$copyrightFiles}) {

      $output{copyrightFiles} = <<HTML;
      <div>Copyright/DRM Info:</div>
      <table style="font-size:10pt;" width="400px;" border="1" cellspacing="2" cellpadding="2">
        <tr>
	  <td>File</td><td>Description</td>
        </tr>
HTML

      foreach my $key (sort { $copyrightFiles->{$b}{timestamp} cmp $copyrightFiles->{$a}{timestamp} } 
                       keys %{$copyrightFiles}) {

        $output{copyrightFiles} .= <<HTML;
        <tr>
	  <td><a href="$copyrightFiles->{$key}{view}" target="_blank">$copyrightFiles->{$key}{name}</a></td>
	  <td>$copyrightFiles->{$key}{comment}</td>
	</tr>
HTML
      }

      $output{copyrightFiles} .= <<HTML;
     </table>
    <br />
HTML
    }

    my %metaData = ();
    $metaData{itemFormat} =
      "<tr><td>Item Format:</td><td><b>${formatName}</b></td></tr>";
    $metaData{devState} =
      "<tr><td>Dev State:</td><td><b>${devStateName}</b></td></tr>";
    $metaData{itemDifficulty} =
      "<tr><td>Difficulty:</td><td><b>${difficultyName}</b></td></tr>";
    $metaData{primaryContentCode} =
      "<tr><td>Primary Content Code:</td><td><b>"
      . (
        $item->{standards}[0]{gle} ? $item->getPrimaryContentCode() : '&nbsp;' )
      . "</b></td></tr>";
    $metaData{secondaryContentCode} =
      "<tr><td>Secondary Content Code:</td><td><b>"
      . ( $item->{standards}[1]{gle}
        ? $item->getSecondaryContentCode()
        : '&nbsp;' )
      . "</b></td></tr>";
    $metaData{tertiaryContentCode} =
      "<tr><td>Tertiary Content Code:</td><td><b>"
      . ( $item->{standards}[2]{gle}
        ? $item->getTertiaryContentCode()
        : '&nbsp;' )
      . "</b></td></tr>";
    $metaData{sourceDoc} =
"<tr><td width=\"150\">Source Documentation:</td><td width=\"400\"><b><span style=\"word-break:break-all;\">$item->{sourceDoc}</style></b></td></tr>";
    $metaData{compCurriculum} =
        "<tr><td>Comprehensive Curriculum:</td><td><b>"
      . ( $item->{$OC_COMP_CURRICULUM} || '&nbsp;' )
      . "</b></td></tr>";
    $metaData{contentArea} =
        '<tr><td>'
      . $labels[$OC_CONTENT_AREA]
      . '</td><td><b>'
      . $const[$OC_CONTENT_AREA]->{ $item->{$OC_CONTENT_AREA} }
      . '</b></td></tr>';
    $metaData{gradeLevel} =
        '<tr><td>'
      . $labels[$OC_GRADE_LEVEL]
      . '</td><td><b>'
      . $const[$OC_GRADE_LEVEL]->{ $item->{$OC_GRADE_LEVEL} }
      . '</b></td></tr>';
    $metaData{itemDOK} =
        '<tr><td>'
      . $labels[$OC_DOK]
      . '</td><td><b>'
      . ( $const[$OC_DOK]->{ $item->{$OC_DOK} || '' } || '' )
      . '</b></td></tr>';
    $metaData{calculator} =
        '<tr><td>'
      . $labels[$OC_CALCULATOR]
      . '</td><td><b>'
      . $calc
      . '</b></td></tr>';
    $metaData{imsId} =
      "<tr><td>IMS ID:</td><td><b>$item->{imsID}</b></td></tr>'";
    $metaData{publicationStatus} =
        "<tr><td>Publication Status:</td><td><b>"
      . $publication_status{ $item->{publicationStatus} }
      . "</b></td></tr>'";

    $metaData{enemies} = '';
    if(exists $metaFieldHash{enemies} && scalar @{$item->{enemies}} ) {

      my @enemy_names = ();

      my $sql = 'SELECT i_external_id FROM item WHERE i_id IN (' . join(',', @{$item->{enemies}}) . ')';
      my $sth = $dbh->prepare($sql);
      $sth->execute();
      while(my $row = $sth->fetchrow_hashref) {

        push @enemy_names, $row->{i_external_id};
      }
      $sth->finish;

      $metaData{enemies} = '<tr><td>Item Enemies:</td><td>'
                         . join ('<br />', @enemy_names)
			 . '</td></tr>';
      
    }

    $metaData{itemPassage} = '';
    if(exists $metaFieldHash{itemPassage} && scalar @{$item->{passages}} ) {

      my $passages = $item->getPassages();

      $metaData{itemPassage} = '<tr><td>Passages:</td><td>'
                             . join ('<br />',
			         map { '<a href="' . $passages->{$_}{url} . '">' . $passages->{$_}{name} . '</a>' }
				 keys %$passages )
                             . '</td></tr>';
    }

    $metaData{itemRubric} = '';
    if(exists $metaFieldHash{itemRubric} && scalar @{$item->{rubrics}} ) {

      my $rubrics = $item->getRubrics();

      $metaData{itemRubric} = '<tr><td>Rubrics:</td><td>'
                             . join ('<br />',
			         map { '<a href="' . $rubrics->{$_}{url} . '">' . $rubrics->{$_}{name} . '</a>' }
				 keys %$rubrics )
                             . '</td></tr>';
    }

    $metaData{itemMetafiles} = '';

    if(exists $metaFieldHash{itemMetafiles}) {

      my $metafiles = $item->getMetafiles();

      if(scalar keys %{$metafiles}) {

        $metaData{itemMetafiles} = '<tr><td>Metafiles:</td><td>'
                             . join ('<br />',
			         map { '<a href="' . $metafiles->{$_}{view} . '">' . $metafiles->{$_}{name} . '</a>' }
				 keys %$metafiles )
                             . '</td></tr>';
        
      }
    }

    $output{itemMetadata} =
'<table style="font-size:10pt;" border="1" cellspacing="3" cellpadding="2">';
    foreach ( @{ $itemMetaFields{$viewType} } ) {
        $output{itemMetadata} .= $metaData{$_};
    }
    $output{itemMetadata} .= '</table><br />';

    my %availableFields = map { $_ => 1 } @{ $viewFields{$viewType} };

    if (   exists( $params->{view_itemNotes} )
        or exists( $availableFields{itemNotes} ) )
    {
        $output{itemNotes} = <<END_HERE;
		<div><b>Item Notes</b></div>
		<table border="1" cellpadding="2" cellspacing="2" style="font-size:10pt;">
		  <tr>
			  <th>User</th><th>Time</th><th>State</th><th width="400">Notes</th>
      </tr>
END_HERE

        my $notes = $item->getAllNotes();

        foreach ( sort { $b cmp $a } keys %{$notes} ) {
            $notes->{$_}{notes} =~ s/\r?\n/<br \/>/g;

            $output{itemNotes} .= <<END_HERE;
	    <tr>
		    <td>$notes->{$_}{lastName}, $notes->{$_}{firstName}</td>
			  <td>$_</td>
			  <td>$notes->{$_}{devState}</td>
			  <td>$notes->{$_}{notes}</td>
		  </tr>	
END_HERE
        }

        $output{itemNotes} .= '</table><br />';
    }

    if (   exists( $params->{view_usageInfo} )
        or exists( $availableFields{usageInfo} ) )
    {
        $output{usageInfo} = <<END_HERE;
    <div style="font-size: 10pt; border:1px solid black; text-align:left; width:150px; padding-left: 3px; padding-bottom: 3px; padding-top: 3px; ">
		  Form: $item->{formName}<br />
			Session: $item->{formSession}<br />
			Sequence: $item->{formSequence}<br />
			Key: $item->{correct}<br />
			IMS ID: $item->{imsID}
		</div>
		<br />
END_HERE
    }

    if (   exists( $params->{view_imsInfo} )
        or exists( $availableFields{imsInfo} ) )
    {
        $item->{$OC_MAP_VALUE} = '' unless exists $item->{$OC_MAP_VALUE};

        $output{imsInfo} = <<END_HERE;
    <div style="font-size: 10pt; border:1px solid black; text-align:left; width:150px; padding-left: 3px; padding-bottom: 3px; padding-top: 3px; ">
			IMS ID: $item->{imsID}<br />
			Key: $item->{correct}<br />
	    Handle: $item->{handle}<br />
			Map Value: $item->{$OC_MAP_VALUE}
		</div>
		<br />
END_HERE
    }

    if (   exists( $params->{view_oibInfo} )
        or exists( $availableFields{oibInfo} ) )
    {
        $item->{$OC_MAP_VALUE}   = '' unless exists $item->{$OC_MAP_VALUE};
        $item->{$OC_SCALE_VALUE} = '' unless exists $item->{$OC_SCALE_VALUE};

        $output{oibInfo} = <<END_HERE;
    <div style="font-size: 10pt; border:1px solid black; text-align:left; width:150px; padding-left: 3px; padding-bottom: 3px; padding-top: 3px; ">
	    Handle: $item->{handle}<br />
			Map location: $item->{$OC_MAP_VALUE}<br />
			Scale value: $item->{$OC_SCALE_VALUE}<br />
			IMS ID: $item->{imsID}<br />
			<!--
			Calculator: ${calc}<br />
			-->
			Key: $item->{correct}
		</div>
		<br />
END_HERE
    }

    # Figure out which fields get printed

    foreach (@totalViewFields) {

        $output{$_} = '' unless exists $output{$_};
        $output{$_} = '' unless exists $availableFields{$_};
    }

    # Print the item display template

    my $usageInfoLabel =
      (       $output{usageInfo} eq ''
          and $output{imsInfo} eq ''
          and $output{oibInfo} eq '' ) ? '' : 'Item Info';

    $html .= <<END_HERE;
	$output{gle}
  <table width="95%" border="0" cellspacing="2" cellpadding="2" class="no-style">
    <tr>
      <td align="left" width="70%">$output{itemId} $output{itemDescription} $output{passageList}</td>
      <td width="10%">&nbsp;</td>
      <td width="20%">${usageInfoLabel}</td>
    </tr>
    <tr>
      <td align="left" valign="top" style="vertical-align:top;">
	    $output{itemContent}
	    $output{distractorRationale}
	    $output{correctResponse}
	  $output{itemMetadata}
	  $output{copyrightFiles}
	  $output{uploadFields}
	  $output{itemNotes}
	  $output{rejectReason}
      </td>
      <td>&nbsp;</td>
      <td valign="top" style="vertical-align:top;">$output{usageInfo} $output{imsInfo} $output{oibInfo}</td>
    </tr>
   </table>
END_HERE

    $html .='<br style="page-break-after:always;" />';

    if ( exists $params->{view_itemRubricContent} ) {

        foreach ( @{ $item->{rubrics} } ) {
            my $rubric = new Rubric( $dbh, $_ );

            $html .= <<END_HERE;
      <table width="510px;" border="0" cellspacing="3" cellpadding="3" class="no-style">
		    <tr><td align="center">Rubric: $rubric->{name}</td></tr>
			  <tr><td>$rubric->{content}</td></tr>
		  </table>
		  <br style="page-break-after:always;" />
END_HERE
        }
    }
    

  return $html;
}

sub get_html_header {

    my $onLoad = $autoPrint ? 'onLoad="window.print();"' : '';

    my $html = <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <title>Item Print Viewer</title>
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css" />
    ${cssIncludeHeader}
    <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
    <script type="text/javascript" src="${commonUrl}mathjax/MathJax.js?config=MML_HTMLorMML"></script>
    <script type="text/javascript">  

      \$(document).ready(function() {

        ${documentReadyFunction}
      });
    </script>
    <style type="text/css">

		td { vertical-align:middle; }
    </style>
  </head>
  <body ${onLoad}>
END_HERE

  return $html;
}

sub get_html_footer {
    return '</body></html>';
}

sub print_no_data {
  my $psgi_out = '';

  my $msg = shift;
  $psgi_out .= <<END_HERE;
  <font size="3" color="red">$msg</font>
END_HERE
  return $psgi_out;
}

1;
