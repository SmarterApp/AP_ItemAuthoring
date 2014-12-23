package Action::itemPreview;

use URI;
use XML::Compile;
use ItemConstants;
use Item;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => join('|', $q->param($_) ) } $q->param;
  our $debug = 1;

  our $documentReadyFunction = '';

  our $this_url = "${orcaUrl}cgi-bin/itemPreview.pl";
  our $edit_url = "${orcaUrl}cgi-bin/itemCreate.pl";

  our $sth;
  our $sql;
  our $item = new Item( $dbh, $in{itemId} );
  our $cssLink = $item->getCssLink();
  $in{itemType} ||= $item->{type};
  our $user  = Session::getUser($q->env, $dbh);
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  unless ( defined( $in{saveAction} ) ) {
    return [ $q->psgi_header('text/html'), [ &print_preview(\%in) ] ];
  }
  
  if ( $in{saveAction} eq 'save' ) {
  
    my $lastDevState = $item->{devState};
  
    $item->{item_body}{content}{text} = $in{'mixedStem'};
  
    $item->setItemFormat( $in{itemFormat} );
    $item->setDescription( $in{itemDescription} );
    $item->setDevState( $in{itemDevState} );
    $item->setDifficulty( $in{itemDifficulty} );
    $item->setNotes( $in{itemNotes} );
    $item->setSourceDoc( $in{sourceDocument} );
    $item->setComprehensiveCurriculum( $in{comprehensiveCurriculum} );
    $item->setPublicationStatus( $in{publicationStatus} );
    $item->setReadabilityIndex( $in{readability_index} );
    $item->setLanguage( $in{language} );
    $item->setDueDate( $in{due_date} );
  
    #$item->setBenchmark($in{benchmark});
    $item->setAuthor( $in{assignedEditor} );
    $item->setLastUser( $user->{id} );
    $item->setContentArea( $in{"ct${OC_CONTENT_AREA}"} );
    $item->setGradeLevel( $in{"ct${OC_GRADE_LEVEL}"} );
    $item->setGradeSpanStart( $in{"ct${OC_GRADE_SPAN_START}"} );
    $item->setGradeSpanEnd( $in{"ct${OC_GRADE_SPAN_END}"} );
    $item->setDOK( $in{"ct${OC_DOK}"} );
    $item->setPoints( $in{"ct${OC_POINTS}"} );
    $item->setFormGroup( $in{"ct${OC_FORM_GROUP}"} );
    $item->setProtractor( $in{"ct${OC_PROTRACTOR}"} );
    $item->setRuler( $in{"ct${OC_RULER}"} );
    $item->setCalculator( $in{"ct${OC_CALCULATOR}"} );
    $item->setCompass( $in{"ct${OC_COMPASS}"} );
  
    $item->save( 'Item Create/Edit', $user->{id}, 'Content Update' );
  
    if ( $in{adminMode} == 2 ) {
  
      &setItemReviewState( $dbh, $item->{id}, $lastDevState,
  			$item->{devState}, $user->{id} );
    }
 

    my $psgi_out = '';

    if ( $in{furl} eq '' ) {
  
      $psgi_out .= <<END_HERE;
    <html>
      <head><title>Item Saved</title>
        <script>
          function doEdit() {
              parent.location.href='$edit_url?myAction=edit&externalId=$in{externalId}&itemBankId=$in{itemBankId}';
          }
        </script>
      </head>
      <body>
      Item Saved!<br/>
      <!--
          <form><input type="button" value="Refresh Content" onClick="doEdit()" /></form>
      -->
      </body>
    </html>
END_HERE
  
    }
    else {
  
      $psgi_out .= <<END_HERE;
    <html>
      <head><title>Item Saved</title></head>
      <body onLoad="parent.location.href='$in{furl}';">
      Item Saved!
      </body>
     </html>
END_HERE
    }

    return [ $q->psgi_header('text/html'), [ $psgi_out ] ];
  }
}

### ALL DONE! ###

sub print_preview {
  my $psgi_out = '';

  my $params     = shift;
  my $item_name_quoted   = $q->escapeHTML( $item->{name} );
  my $descrip        = $params->{itemDescription};
  my $descripSafe    = $q->escapeHTML( $params->{itemDescription} );
  my $notesSafe      = $q->escapeHTML( $params->{itemNotes} );
  my $sourceDocument = $q->escapeHTML( $params->{sourceDocument} );
  my $comprehensiveCurriculum =
    $q->escapeHTML( $params->{comprehensiveCurriculum} );
  my $readabilityIndex =
    $q->escapeHTML( $params->{readability_index} || '' );
  my $formatName       = $item_formats{ $in{itemFormat} };
  my $devStateName = $dev_states{$in{itemDevState}};
  my $difficultyName = $difficulty_levels{$in{itemDifficulty}};
  my $dokName        = $const[$OC_DOK]->{ $in{"ct${OC_DOK}"} };
  my $furl           = $params->{furl};
  my $assignedEditor = $params->{assignedEditor};
  my $adminMode      = $params->{adminMode} || 0;
  my @errorList      = ();

  $in{'mixedStem'} = &fixHTML( &unescapeHTML( $in{'mixedStem'} ));

  # Validate content
  $@ = 0;
  eval {
    my $x_parsed = XML::Compile->dataToXML('<span>' . &encodeHTML($in{'mixedStem'}) . '</span>');
  };

  if ($@) {
    push @errorList, "Item Body: Content Problem => $@";
  }

  # If any of the content was bad, quit early
  if ( scalar(@errorList) > 0 ) {
    $psgi_out .= <<END_HERE;
      <!DOCTYPE html>
	<html>
	  <head>
		</head>
		<body>
		  <h3>The following errors must be fixed before saving:</h3>
			<ul>
END_HERE

    foreach (@errorList) { $psgi_out .= "<li>$_</li>\n"; }

    $psgi_out .= <<END_HERE;
	 </ul>
	 <pre>
	   $in{mixedStem}
	 </pre>
	</body>
</html>
END_HERE
    return $psgi_out;
  }

  $item->{item_body}{content}{text} = $in{'mixedStem'};

  my $charDisplay = "";
  my $charHidden  = "";
  foreach my $type ( @ctypes, @tools )
  {
    $charDisplay .=
	    '<tr><td><span class="text">'
	  . $labels[$type]
	  . '</span></td>'
	  . '<td><b>'
	  . (
		defined( $in{"ct${type}"} )
		  && defined( $const[$type]->{ $in{"ct${type}"} } )
		? $const[$type]->{ $in{"ct${type}"} || -9 }
		: ''
	    )
	  . '</b></td></tr>';

    $charHidden .=
	    '<input type="hidden" name="ct' . $type
	  . '" value="'
	  . ( defined( $in{"ct${type}"} ) ? $in{"ct${type}"} : '' ) . '" />';
  }

  my $contentInputFields = '';

  $contentInputFields .=
	    '<input type="hidden" name="mixedStem" value="'
	  . $q->escapeHTML( &fixHTML( $in{"mixedStem"} ) )
	  . '" />';

  my $mediaAssets = &getMediaAssetAttributes( $dbh, $item->{id} );

  if ( scalar( @{$mediaAssets} ) > 0 ) {
    $documentReadyFunction .= '$("#noMediaMessage").hide();';

    # clear persistsed item part information will be getting information from content tab
    for ( @{$mediaAssets} ) {
	$_->{"i_part"} = "<i>Unassigned</i>";
    }

    # get list of media tags from stem
    while ( $params->{"mixedStem"} =~ m/"orca:media:([^"]+)"/g ) {
      my $fileName = $1;
      foreach ( @{$mediaAssets} ) {
        if ( $_->{"iaa_filename"} =~ m/$fileName/ ) {
          my $partName = 'Item Body';
          if ( $_->{"i_part"} !~ m/$partName/ ) {
            if ( $_->{"i_part"} =~ m/Unassigned/ ) {
  	      $_->{"i_part"} = $partName;
	    }
	    else {
	      $_->{"i_part"} = join ', ', $_->{"i_part"},
				  $partName;
	    }
	  }
 	}
      }
    }

    my $ii_id = (keys %{$item->{interactions}})[0];
    my $ii = $item->{interactions}{$ii_id};
    if($ii->{type} == $IT_CHOICE) {

      my $choices = scalar(@{$ii->{content}{choices}}) || 0;

      for ( my $i = 0; $i < $choices ; $i++ ) {
        next unless defined($ii->{content}{choices}[$i]{text});
        while ( $ii->{content}{choices}[$i]{text} =~ m/"orca:media:([^"]+)"/g ) {

          my $fileName = $1;
          foreach ( @{$mediaAssets} ) {
   	    if ( $_->{"iaa_filename"} =~ m/$fileName/ ) {
	      my $partName = "Choice " . chr( 65 + $i );
	      if ( $_->{"i_part"} !~ m/$partName/ ) {
	        if ( $_->{"i_part"} =~ m/Unassigned/ ) {
	 	  $_->{"i_part"} = $partName;
		}
		else {
		  $_->{"i_part"} = join ', ', $_->{"i_part"},
			  $partName;
		}
              }
	    }
	  }
	}
      }
    }
  }

  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    <meta http-equiv="X-UA-Compatible" content="IE=9" />
    <title>Item Preview</title>
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    ${cssLink}
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script type="text/javascript" src="${commonUrl}mathjax/MathJax.js?config=MML_HTMLorMML"></script>
  <style type="text/css">

  </style>
  <script type="text/javascript">

      \$(document).ready(function() {
        jQuery("#mediaAssetTable").tablesorter({headers:{4:{sorter:false}}});
        ${documentReadyFunction}

      });
 
    function doSaveSubmit() {

      if(document.itemCreate.itemFormat.value == '' ) {
        alert('Please select Item Format before Saving!');
	return;
      }

      if(document.itemCreate.itemDescription.value == '' ||
	   document.itemCreate.itemDifficulty.value == '0' ||
	   document.itemCreate.itemDifficulty.value == ''
       ) {
	 alert('You must enter a Description and Difficulty.');
	 return;
      }	 
      document.itemCreate.saveAction.value = 'save';
      document.itemCreate.submit();
    }

		function scaleImages(dir) {
      var scale = .8; 
			if(dir == 'up') {
        scale = 1.2;
      }

      var objs = document.getElementsByTagName('embed');
      var i;
			for(i in objs) {
			  objs[i].width = scale * objs[i].width;
				objs[i].height = scale * objs[i].height;
			}
		}

      function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
    return true; 
      }

  </script>
  </head>
  <body>
	  <!--
	  <input type="button" value="Scale Up" onClick="scaleImages('up');" />&nbsp;
		<input type="button" value="Scale Down" onClick="scaleImages();" /><br />
    -->
    <form name="itemCreate" action="itemPreview.pl" method="POST">
     <input type="hidden" name="saveAction" value="" />
     <input type="hidden" name="externalId" value="${item_name_quoted}" />
     <input type="hidden" name="itemId" value="$item->{id}" />
     <input type="hidden" name="itemBankId" value="$item->{bankId}" />
     <input type="hidden" name="furl" value="${furl}" />
     <input type="hidden" name="itemDifficulty" value="$in{itemDifficulty}" />
     <input type="hidden" name="itemDevState" value="$in{itemDevState}" />
     <input type="hidden" name="assignedEditor" value="${assignedEditor}" />
     <input type="hidden" name="sourceDocument" value="${sourceDocument}" />
     <input type="hidden" name="comprehensiveCurriculum" value="${comprehensiveCurriculum}" />
     <input type="hidden" name="publicationStatus" value="$in{publicationStatus}" />
     <input type="hidden" name="readability_index" value="${readabilityIndex}" />
     <input type="hidden" name="language" value="$in{language}" />
     <input type="hidden" name="due_date" value="$in{dueDate}" />
     
     <input type="hidden" name="adminMode" value="${adminMode}" />
     ${charHidden}
     ${contentInputFields}
     <input type="hidden" name="itemDescription" value="${descripSafe}" />
     <input type="hidden" name="itemFormat" value="$in{itemFormat}" />
     <input type="hidden" name="itemNotes" value="${notesSafe}" />
END_HERE

  unless ( $item->{readOnly} ) {
    $psgi_out .= <<END_HERE;
	<p><input type="button" value="Save Item" onClick="return doSaveSubmit();"/></p>
	 <br />
END_HERE
  }
	
  $psgi_out .= '</form>';

  my $c = $item->getDisplayContent();
  my $has_correct_response = 0;
  my $has_distractor_rationale = 0;

  foreach my $ii_id (keys %{$item->{interactions}}) {
    if($item->{interactions}{$ii_id}{type} == $IT_CHOICE) {
      $has_correct_response = 1;
      $has_distractor_rationale = 1;
    } 
    elsif($item->{interactions}{$ii_id}{type} == $IT_TEXT_ENTRY) {
      $has_correct_response = 1;
    }
    elsif($item->{interactions}{$ii_id}{type} == $IT_INLINE_CHOICE) {
      $has_correct_response = 1;
    }
  }

  $psgi_out .= $c->{itemBody} . '<br />'; 
  $psgi_out .= $c->{correctResponse} . '<br />' if $has_correct_response;
  $psgi_out .= $c->{distractorRationale} . '<br />' if $has_distractor_rationale;

  $psgi_out .= "<br />" . &getMediaTableHtml($mediaAssets);

  $psgi_out .= <<END_HERE;
	 <br />
	 <table border="1" cellpadding="3" cellspacing="1">
	   <tr>
		   <td>Description:</td><td>${descrip} &nbsp;</td>
		 </tr>
		 <tr>
		   <td>Difficulty:</td><td>${difficultyName} &nbsp;</td>
		 </tr>
		 <tr>
		   <td>Source Doc:</td><td>${sourceDocument} &nbsp;</td>
		 </tr>
		 <tr>
		   <td>Passage:</td><td>
END_HERE

  my $passages = $item->getPassages();

  foreach (%$passages) {
    $psgi_out .= '<div><a href="' . $orcaUrl
	  . 'cgi-bin/passageView.pl?passageId='
	  . $_
	  . '" target="_blank">'
	  . $passages->{$_}{name}
	  . '</a></div>';
  }

  $psgi_out .= <<END_HERE;
        &nbsp;</td>
		 </tr>
		 <tr>
		   <td>Rubric:</td><td>
END_HERE

  my $rubrics = $item->getRubrics();

  foreach (%$rubrics) {
    $psgi_out .= '<div><a href="' . $orcaUrl
	  . 'cgi-bin/rubricView.pl?rubricId='
	  . $_
	  . '" target="_blank">'
	  . $rubrics->{$_}->{name}
	  . '</a></div>';
  }

  $psgi_out .= <<END_HERE;
        &nbsp;</td>
		 </tr>
		 <tr>
		   <td>Notes:</td><td><textarea rows="5" cols="40" readonly>${notesSafe}</textarea></td>
		 </tr>	 
	 </table>	 
	</body>
</html>         
END_HERE

  return $psgi_out;
}

sub encodeHTML {
	my $html = shift;
	$html =~ s/&/&amp;/g;

	#$html =~ s/</&lt;/g;
	#$html =~ s/>/&gt;/g;
	return $html;
}

sub fixHTML {

  my $html = shift;
	return '' unless defined $html;
	$html =~ s/http:\/\/$env->{SERVER_NAME}//gs;
	$html =~ s/<\/span[^>]+>/<\/span>/gs;
	$html =~ s/<\/td[^>]+>/<\/td>/gs;
	$html =~ s/<\/li[^>]+>/<\/li>/gs;
	$html =~ s/<\/p [^>]+>/<\/p>/gs;
	$html =~ s/<\/a [^>]+>/<\/a>/gs;
	$html =~ s/<align="\w*"><\/align="\w*">//gs;
	$html =~ s/<\/?st1:[^>]*>//gs;
	$html =~ s/<\/?o:[^>]*>//gs;
	$html =~ s/<\/?v:[^>]*>//gs;
	$html =~ s/<\/?w:[^>]*>//gs;
	$html =~ s/<ro:/</g;
	$html =~ s/<\/ro:/<\//g;
	$html =~ s/<\/>//g;

	$html =~ s/<object([^>]+)wmode="transparent"/<object$1/g;
	$html =~ s/<object /<object wmode="transparent" /g;
  while ( $html =~ m/(?:value|flashvars)="(?:[^"]*)\&amp;amp;/ ) {
		$html =~
		  s/(value|flashvars)="([^"]*?)\&(?:amp;){2,}([^"]*)"/$1="$2\&amp;$3"/s;
  }

  return &replaceChars($html);
}
1;
