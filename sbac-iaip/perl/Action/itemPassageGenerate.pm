package Action::itemPassageGenerate;

use ItemConstants;
use UrlConstants;
use Item;
use Data::Dumper;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  our $hd;
  
  our $HD_SS_CONTENT = 6;
  our $HD_AREA = 3;
  
  our %cross_ccs = (
      '0' => 'None',
      '1' => 'Science/Technology/Math',
      '2' => 'Social Studies',
      '3' => 'Fine Arts',
      '4' => 'Health/Physical Education'
  );
  
  our %char_ethnicities = (
      '0' => 'None',
      '1' => 'White',
      '2' => 'African-American',
      '3' => 'Native American',
      '4' => 'Asian-American',
      '5' => 'Mexican-American/Latino',
      '6' => 'Foreign'
  );
  
  our %char_genders = (
      '0' => 'None',
      '1' => 'Male',
      '2' => 'Female'
  );
  
  unless ( $user->{type} == $UT_ITEM_EDITOR and $user->{adminType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ]];
  }
  
  $in{myAction} = '' unless exists $in{myAction};
  
  # Allow the standard hierarchy to be selected
  $sql = "SELECT * FROM standard_hierarchy";
  $sth = $dbh->prepare($sql);
  $sth->execute()
    || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
  $in{model} = {};
  while ( my $row = $sth->fetchrow_hashref ) {
      $in{model}->{ $row->{sh_id} }   = $row->{sh_name};
      $in{idArray}->{ $row->{sh_id} } = $row->{hd_id};
  }
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_first_screen(\%in) ]]; 
  }
  
  unless ( exists $in{passageId} ) {
  
      # Create the Passage
  
      my $psg = new Passage($dbh);
  
      unless ( $psg->create( $in{itemBank}, $in{passageName} ) ) {
          $in{message} =
  "Passage '$in{passageName}' already exists. Please choose another name.";
 
          return [ $q->psgi_header('text/html'), [ &print_first_screen(\%in) ]];
      }
  
      $psg->setGenre( $in{genre} );
      $psg->setSubGenre( $in{subgenre} );
      $psg->setTopic( $in{topic} );
      $psg->setReadingLevel( $in{readingLevel} );
      $psg->setSummary( $in{summary} );
      $psg->setCrossCurriculum( $in{crossCurriculum} );
      $psg->setCharEthnicity( $in{charEthnicity} );
      $psg->setCharGender( $in{charGender} );
      $psg->setLanguage( $in{language} );
      $psg->setGradeSpanStart( $in{gradeSpanStart} );
      $psg->setGradeSpanEnd( $in{gradeSpanEnd} );
      $psg->setReadabilityIndex( $in{readabilityIndex} );
      $psg->setContentArea( $in{contentArea} );
      $psg->setGradeLevel( $in{gradeLevel} );
      #$psg->setCode( $in{passageCode} );
      $psg->setProject( $in{itemProject} );
      $psg->save();
  
      $in{passageId} = $psg->{id};
  
  }
  
  our $editors = &getEditors($dbh, $in{itemBank} || 0);
  
  if ( $in{myAction} eq 'create' ) {
  
    my @itemList = ();
    my @itemIdList = ();
  
    my $psg = new Passage( $dbh, $in{passageId} );
    $psg->setAuthor( $in{itemWriter} );
    $psg->save();
  
    my $writerCode = '';
    $sql = "SELECT * FROM user WHERE u_id = " . $in{itemWriter};
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $writerCode = $row->{u_writer_code};
    }
  
    foreach my $formatKey ( grep /^formatCount/, keys %in ) {
  
      $formatKey =~ /^formatCount(\d+)_(\d+)/;
  
      my $gleId    = $1;
      my $formatId = $2;
       
      my $type;
      my $points;
  
      if ( $formatId == 1 ) {
        $type   = $IT_X_MC;
        $points = 1;
      }
      elsif ( $formatId == 2 ) {
        $type   = $IT_EXTENDED_CR;
        $points = 2;
      }
      elsif ( $formatId == 3 ) {
        $type   = $IT_EXTENDED_CR;
        $points = 3;
      }
      elsif ( $formatId == 4 ) {
        $type   = $IT_EXTENDED_CR;
        $points = 4;
      }
      elsif ( $formatId == 5 ) {
        $type   = $IT_EXTENDED_CR;
        $points = 12;
      }
  
      # Build the Item External ID
  
      #my $externalIdPrefix =
      #      &getNewItemPrefix( $dbh, $in{contentArea}, $in{gradeLevel}, $gleId,
      #        undef, $formatId, $in{passageId} );
      #my $firstSuffix =
      #      &getNextItemSequence( $dbh, $in{itemBank}, $externalIdPrefix );
  
      # 2) Generate the item sequence
  
      $in{$formatKey} = 0 if $in{$formatKey} eq '';
  
      for ( my $i = 0 ; $i < $in{$formatKey} ; $i++ ) {
  
        #my $thisExternalId =
        #        sprintf( '%s%02d', $externalIdPrefix, $firstSuffix + $i );
  
        my $item = new Item($dbh);
        $item->create( $in{itemBank}, '', undef, $writerCode,$in{primarystandard}  );
  
        my $thisExternalId = $item->{name};
  
        $item->setType($type);
        $item->setAuthor( $in{itemWriter} );
        $item->setContentArea( $in{contentArea} );
        $item->setGradeLevel( $in{gradeLevel} );
        $item->setGradeSpanStart ( $in{gradeSpanStart} );
        $item->setGradeSpanEnd ( $in{gradeSpanEnd} );
        $item->setReadabilityIndex( $in{readabilityIndex} );
        $item->setPoints($points);
        $item->setItemFormat($formatId);
        $item->setProject( $in{itemProject} || 0 );
        $item->setDueDate( $in{dueDate} );
  
        $item->save('Passage Set Generator', $user->{id}, 'Created Item');
  
        # Assign the standard, passage
        $item->insertChar( $OC_ITEM_STANDARD, $gleId ) if $gleId;
        $item->insertChar( $OC_PASSAGE,  $in{passageId} );
  
        # Create a 'passage_item_set' entry
        my $sql =
  "INSERT INTO passage_item_set SET p_id=$in{passageId}, i_id=$item->{id}, pis_sequence="
            . ( $i + 1 );
        my $sth = $dbh->prepare($sql);
        $sth->execute();
  
        push @itemList, $thisExternalId;
        push @itemIdList, $item->{id};
      }
    }
    
    # Send e-mail to writer that they have items
  
    my $notification_status = &sendNewItemNotification($dbh, $banks->{$in{itemBank}}{name}, $in{itemWriter});
    $in{message} = 'Unable to send e-mail notification to item assignee.' unless $notification_status;
  
    return [ $q->psgi_header('text/html'), [ &print_report(\%in, \@itemList) ]];
  }
  
  $in{text} = {};    #Holds the text descriptions
 # for ( my $i = 0 ; $i <= $in{level} ; $i++ ) {
  
      # Build one drop-down list ( 1 step of the hierarchy )
     # my $iplus = $i + 1;
     # my $sql   = "SELECT * FROM hierarchy_definition WHERE hd_parent_id="
       # . $in{"hdId${i}"};
      #$sth = $dbh->prepare($sql);
      #$sth->execute()
      #  || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
  
     # $in{"model${iplus}"} = {};    # hd_id to hd_value map
      #$in{"pos${iplus}"}   = {};    # hd_id to hd_posn_in_parent map
     # while ( my $row = $sth->fetchrow_hashref ) {
       #   $in{"model${iplus}"}->{ $row->{hd_id} } = $row->{hd_value};
        #  $in{"pos${iplus}"}->{ $row->{hd_id} }   = $row->{hd_posn_in_parent};
        #  $in{"type${iplus}"}                     = $row->{hd_type};
  
         # if ( $row->{hd_std_desc} || $row->{hd_type} == $HD_SS_CONTENT ) {
           #   $in{text}->{ $row->{hd_id} } = $row->{hd_std_desc} || '';
  
              #$in{textType} = $row->{hd_type};
         # }
  
      #}
  #}
  
 # unless ( defined $in{label1} ) {
  
      # Save all labels for later use
    #  my $sql = "SELECT * FROM qualifier_label WHERE sh_id=$in{hierarchyId}";
      #$sth = $dbh->prepare($sql);
     # $sth->execute()
      #  || warn( "Failed Query:" . $dbh->err . "," . $dbh->errstr );
    #  while ( my $row = $sth->fetchrow_hashref ) {
       #   $in{"label$row->{ql_type}"} = $row->{ql_label};
     # }
  #}
  
 # $in{level} = $in{level} + 1;

  return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
}
### ALL DONE! ###

sub print_report {

    my $params   = shift;
    my $itemList = shift;

    my $itemCount = scalar( @{$itemList} );

    my $itemListHtml = '';
    foreach my $itemName ( sort { $a cmp $b } @{$itemList} ) {
        $itemListHtml .= "${itemName}<br />";
    }
    my $itemBankName = $banks->{ $params->{itemBank} }{name};
    my $editorName   = $editors->{ $params->{itemWriter} };

    my $msg = defined($in{message}) ? '<div style="color:red;">' . $in{message} . '</div>' : ''; 

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Passage/Item Creation Report</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
     </head>
  <body>
    <div class="title">Created Passage '$params->{passageName}'</div>
    ${msg}
    <p><b>Created ${itemCount} New Items</b></p>
    <p>Program: ${itemBankName}
    <br />
    Assigned To: ${editorName}</p>
    <p> 
    ${itemListHtml}
    </p> 
  </body>
</html>
END_HERE
}

sub print_first_screen {

    my $params = shift;

    my $model  = $params->{model};
    my $hd_ids = $params->{idArray};

    my $msg = (
        defined $params->{message}
        ? '<div style="color:red;">' . $params->{message} . '</div>'
        : '' );

    my $jsArray = "var idArray = new Array();\n";
    foreach my $key ( keys %{$hd_ids} ) {
        $jsArray .= 'idArray["' . $key . '"] = "' . $hd_ids->{$key} . "\";\n";
    }

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $itemBank = ( defined $params->{itemBank} ? $params->{itemBank} : '1' );
    my $itemBankHtml =
      &hashToSelect( 'itemBank', \%itemBanks, $itemBank, 'changeItemBank();',
        '', '', '' );

    my $itemProjectHtml =
      &hashToSelect( 'itemProject', &getProjects( $dbh, $itemBank ),
        '', '', '', '', 'font-size:11px;' );

    my $contentArea =
      ( defined $params->{contentArea} ? $params->{contentArea} : '' );
    my $contentAreaHtml =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        $contentArea, '', 'null', '', '' );

    my $gradeLevel =
      ( defined $params->{gradeLevel} ? $params->{gradeLevel} : '' );
    my $gradeLevelHtml =  &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], $gradeLevel, '', 'null', '', '');

    my $gradeSpanStartList = hashToSelect( 'gradeSpanStart', $const[$OC_GRADE_SPAN_START], '', 'compareGradeSpan(this);', '');	
    my $gradeSpanEndList = hashToSelect( 'gradeSpanEnd', $const[$OC_GRADE_SPAN_END], '', 'compareGradeSpan(this);', '');	

    my $genreList = &hashToSelect( 'genre', \%genres, '', '', '' );
    my $crossCurriculumList =
      &hashToSelect( 'crossCurriculum', \%cross_ccs, '', '', '' );
    my $charEthnicityList =
      &hashToSelect( 'charEthnicity', \%char_ethnicities, '', '', '0' );
    my $charGenderList =
      &hashToSelect( 'charGender', \%char_genders, '', '', '' );
    my $languageDisplay = &hashToSelect('language',\%languages, '','','');

    my $dispList = &hashToSelect(
        'hierarchyId',
        $model,
        '', '', '' );

    my $dueDate = $params->{dueDate} || '';
    my $readabilityIndex = $params->{readabilityIndex} || '';

    return <<END_HERE;
<!DOCTYPE HTML>
<html>
  <head>
    <title>Passage/Item Creation</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <script src="${commonUrl}js/calendar/cal2.js" type="text/javascript"></script>
    <script language="JavaScript">
    <!--
     ${jsArray} 
      
      function mySubmit()
      {

       // var strvalue = document.itemStandard.hierarchyId.options[document.itemStandard.hierarchyId.selectedIndex].value;
        //var strtext = document.itemStandard.hierarchyId.options[document.itemStandard.hierarchyId.selectedIndex].text;
        

        if(document.itemStandard.passageName.value == '') {

	  alert('Please enter a Passage Name.');
	  return false;
	}

    if(document.itemStandard.itemBank.selectedIndex == 0) {
	  alert('Please select a Program.');
	  return false;
	 }
	if( document.itemStandard.contentArea.value == '' ) {
	    alert( 'Please enter a Subject.');	  
	       return false;
	     }
	     if( document.itemStandard.gradeLevel.value == '' ) {
	    alert( 'Please enter a Grade Level.');	  
	       return false;
	     }
	
        if( document.itemStandard.dueDate.value == '' ) {
	    alert( 'Please enter a Due Date.');	  
	       return false;
	     }
	
        /*
	if(document.itemStandard.hierarchyId.selectedIndex == 0) {
	  alert('Please select a Hierarchy.');
	  return false;
	}
	*/

        //document.itemStandard.hdId0.value = idArray[strvalue];
	//document.itemStandard.label0.value = strtext;
	document.itemStandard.myAction.value = 'list';
	document.itemStandard.submit();
        return true; 
      }

      function changeItemBank() {
			  document.itemStandard.myAction.value = '';
				document.itemStandard.submit();
				return true;
			}	

      addCalendar("calendar1", "Select Date", "dueDate", "itemStandard");
      setWidth(90, 1, 15, 1);
      setFormat("yyyy-mm-dd");

      function compareGradeSpan(gs) {

        var gs_start = document.itemStandard.gradeSpanStart.options[document.itemStandard.gradeSpanStart.selectedIndex].text;
        var gs_end = document.itemStandard.gradeSpanEnd.options[document.itemStandard.gradeSpanEnd.selectedIndex].text;

        if( gs_start == '' || gs_end == '' || gs_start == '-' || gs_end == '-' ) return;

        if( document.itemStandard.gradeSpanStart.selectedIndex >= document.itemStandard.gradeSpanEnd.selectedIndex ) {
            alert( 'Grade Span End must be greater than Grade Span Start!' );
            gs.selectedIndex = 0;
            gs.focus();
        }
      }

    //-->
    </script>
  </head>
  <body>
    <div class="title">Create New Passage/Items</div>
		${msg}
    <form name="itemStandard" action="itemPassageGenerate.pl" method="POST">
      <input type="hidden" name="hdId0" value="" />
      <input type="hidden" name="label0" value="" />
      <input type="hidden" name="level" value="0" />
      <input type="hidden" name="myAction" value="" />
      
    <table border="0" cellpadding="4" cellspacing="4">
      <tr><td><span class="required">Program:</span></td>
          <td>${itemBankHtml}</td></tr>
      <tr><td><span class="required">Passage Name:</span></td>
          <td><input type="text" size="40" name="passageName" value="" /></td></tr>
      <tr><td><span class="required">Subject:</span></td>
          <td>${contentAreaHtml}</td></tr>
      <tr><td><span class="required">Grade Level:</span></td>
          <td>${gradeLevelHtml}</td></tr>
      <tr><td><span>$labels[$OC_GRADE_SPAN_START]</span></td><td>${gradeSpanStartList}</td></tr> 
      <tr><td><span>$labels[$OC_GRADE_SPAN_END]</span></td><td>${gradeSpanEndList}</td></tr> 
      <tr><td><span>Summary:</span></td>
          <td><textarea name="summary" rows="2" cols="45"></textarea></td></tr>
      <tr><td><span>Genre:</span></td>
          <td>${genreList}</td></tr>
      <tr><td><span>Sub-Genre:</span></td>
          <td><input type="text" name="subgenre" value="" size="35" /></td></tr>
      <tr><td><span>Topic:</span></td>
              <td><input type="text" name="topic" value="" size="35" /></td></tr>
      <tr><td><span >Reading<br />Level Notes:</span></td>
          <td><textarea name="readingLevel" rows="2" cols="45"></textarea></td></tr>
      <tr><td><span>Readability Index:</span></td><td><input type="text" name="readabilityIndex" value="$readabilityIndex" size="30" /></td></tr>
      <tr><td><span>Cross Curriculum:</span></td><td>${crossCurriculumList}</td></tr>
      <tr><td><span>Character Ethnicity:</span></td><td>${charEthnicityList}</td></tr>
      <tr><td><span>Character Gender:</span></td><td>${charGenderList}</td></tr>
      <tr><td><span>Language:</span></td><td>${languageDisplay}</td></tr>
      <tr>
        <td><span class="required">Due Date:</span></td>
    <td>
       <input type="text" id="dueDate" name="dueDate" size="11" value="$dueDate" readonly="readonly" onclick="javascript:showCal('calendear1')" />
           &nbsp;<a href="javascript:showCal('calendar1')">Select Date</a>
       <div id="calendar1"></div>
    </td>
      </tr>
     <!--  <tr><td><span class="text">Hierarchy:</span></td><td>${dispList}</td></tr> -->
      <tr><td colspan="2"><input type="button" name="save" value="Next Step" onClick="mySubmit();" /></td></tr>
    </table>
    </form>
  </body>
</html>
END_HERE
}

sub print_welcome {
  my $psgi_out = '';

    my $params = shift;

    my $projects        = &getProjects( $dbh, $params->{itemBank} );
    my $itemProjectName = $projects->{ $params->{itemProject} };
    my $itemBankName    = $banks->{ $params->{itemBank} }{name};
    my $contentAreaName = $const[$OC_CONTENT_AREA]->{ $params->{contentArea} };
    my $gradeLevelName  = $const[$OC_GRADE_LEVEL]->{ $params->{gradeLevel} };

    my $hId      = $params->{hierarchyId};
    my $hdIdRoot = $params->{hdId0};
    my $hLabel   = $params->{label0};

    my $dueDate = $params->{dueDate};
    my $readabilityIndex = $q->escapeHTML($params->{readabilityIndex} || '');
    
     my $contentArea =
      ( defined $params->{contentArea} ? $params->{contentArea} : '' );
    my $contentAreaHtml =
      &hashToSelect( 'contentArea', $const[$OC_CONTENT_AREA],
        $contentArea, 'clearStandard()', '', '', '' );

    my $gradeLevel =
      ( defined $params->{gradeLevel} ? $params->{gradeLevel} : '' );
    my $gradeLevelHtml =  &hashToSelect( 'gradeLevel', $const[$OC_GRADE_LEVEL], $gradeLevel, 'clearStandard()', '', '', '');

    my $selectHtml = "";

    my $buildTable = 0;

    for ( my $i = 1 ; $i <= $params->{level} ; $i++ ) {
        $selectHtml .=
            '<tr><td><span class="text">'
          . $params->{ 'label' . $params->{"type${i}"} }
          . ':</span></td>'
          . '<td><select name="hdId'
          . $i . '"'
          . ' onChange="mySubmit('
          . $i
          . '); return true;">'
          . '<option value=""></option>';

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

        $selectHtml .= '</select></td></tr>';

        last if $params->{"type${i}"} == $HD_AREA;
    }

    my $currentLevel = $params->{level} - 1;

    $params->{"type${currentLevel}"} ||= -99;
    $buildTable = 1 if $params->{"type${currentLevel}"} == $HD_AREA;

    my $hiddenHtml = "";

    foreach my $key ( grep { /^label/ } keys %$params ) {
        $hiddenHtml .=
            '<input type="hidden" name="' 
          . $key
          . '" value="'
          . $params->{$key} . '" />';
    }

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html>
  <head>
    <title>Passage/Item Creation</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
       <script language="JavaScript">
    <!--
       
    function openEditWindow(subject,grade){    
   
    if(!subject){
    alert("Please select a Subject to Assign Standard!");
    return false;
    }
     if(!grade){
     alert("Please select a Grade Level to Assign Standard!");
    return false;
     }

   myOpen('Edit',  "/orca-sbac/ItemStandardEdit.jsf?subject="+subject+"&grade="+grade+"&standardInd=P&callerFlag=itemGenerator", 700, 500);
}
 function myOpen(name,url,w,h)
      {
        var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,left=250,top=100,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
    return true; 
      }
function getStandardTable(value){
        document.getElementById("standard_bp").style.display="table";
        document.getElementById("item_id").innerHTML=value;
}
    

      function mySubmit(level)
      {
        document.itemStandard.level.value = level;
	document.itemStandard.myAction.value = 'list';
	document.itemStandard.submit();
        return true; 
      }
      
      function doSave(f)
      {
      
      if( document.itemStandard.contentArea.value == '' ) {
	    alert( 'Please enter a Subject.');	  
	       return false;
	     }
	     if( document.itemStandard.gradeLevel.value == '' ) {
	    alert( 'Please enter a Grade Level.');	  
	       return false;
	     }

     if(document.itemStandard.primarystandard.value==''){
             alert('Please Assign a Standard');
              return false;
       }     
      
	if( document.itemStandard.itemWriter.length == 0 || 
	    document.itemStandard.itemWriter.options[document.itemStandard.itemWriter.selectedIndex].value == '') {
	  alert('Please select an Item Writer to assign items to.');
	  return false;
        }
        document.getElementById('progress_spinner').innerHTML = '<img src="/common/images/spinner.gif" />';
	document.itemStandard.myAction.value = 'create';
        document.itemStandard.submit();
	return true;
      }
      
      function clearStandard(){
document.getElementById('item_standard').value='';
document.getElementById("standard_bp").style.display="none";
}

    //-->
    </script>
  </head>
  <body >
    <div class="title">Create New Passage/Items</div>
    <form name="itemStandard" action="itemPassageGenerate.pl" method="POST">
      <input type="hidden" name="hierarchyId" value="${hId}" />
      <input type="hidden" name="hdId0" value="${hdIdRoot}" />
      <input type="hidden" name="level" value="" />
      <input type="hidden" name="myAction" value="" />
      
			<input type="hidden" name="itemBank" value="$params->{itemBank}" />
			<input type="hidden" name="itemProject" value="$params->{itemProject}" />
			<input type="hidden" name="passageId" value="$params->{passageId}" />
			<input type="hidden" name="passageName" value="$params->{passageName}" />
			<!--
			<input type="hidden" name="passageCode" value="$params->{passageCode}" />
			-->
			
			<input type="hidden" name="gradeSpanStart" value="$params->{gradeSpanStart}" />
			<input type="hidden" name="gradeSpanEnd" value="$params->{gradeSpanEnd}" />
			<input type="hidden" name="dueDate" value="$params->{dueDate}" />
			<input type="hidden" name="readabilityIndex" value="${readabilityIndex}" />
      ${hiddenHtml}
    <table class="standards" border="0" cellpadding="2" cellspacing="2">
      <tr><td><span class="text">Program:</span></td><td>${itemBankName}</td></tr> 
      <tr><td><span class="text">Passage Name:</span></td><td>$params->{passageName}</td></tr> 
      <tr><td><span class="required">Subject:</span></td><td>${contentAreaHtml}</td></tr> 
      <tr><td><span class="required">Grade Level:</span></td><td>${gradeLevelHtml}</td></tr> 
      <!-- <tr><td><span class="text">Hierarchy:</span></td><td>${hLabel}</td></tr> -->
      <tr><td><span class="required">Standard</span></td><td><input type="text" name="primarystandard" id="item_standard" onChange="getStandardTable(this.value)" readonly /> 
      <a href="#" onclick="openEditWindow(document.itemStandard.contentArea.options[document.itemStandard.contentArea.selectedIndex].innerHTML ,document.itemStandard.gradeLevel.options[document.itemStandard.gradeLevel.selectedIndex].innerHTML);"> Assign Standard</a>
      </td></tr> 
      <!-- ${selectHtml} -->
    
    
    		
END_HERE
#added for passage generation after modification for standard geneartion
 my $itemWriterDisplay =
          &hashToSelect( 'itemWriter', $editors, '4856', '', '', 'value',
            'font-size:11px;' );

      $psgi_out .= <<END_HERE;
    
      <tr>
        <td><span class="text">Assigned Writer:</span></td><td>${itemWriterDisplay}</td>
      </tr>
   </table> 
   <table  cellspacing="2" cellpadding="2" id="standard_bp" name="standard_bp" style="display:none" >
	<tr>
	  <th>Standard: </th>
	  <th>Selected Response</th>
	  <th>Constructed Response</th>
	  <th>Activity Based</th>
	  <th>Performance</th>
	</tr>
	<tr>
	  <td id="item_id" size="5" ></td>
	  <td><input type="text" class="inputtype_text" name="formatCount11_1" id="formatCount11_1" size="2" maxlength="2"/></td>
	  <td><input type="text" class="inputtype_text" name="formatCount22_2" id="formatCount22_2" size="2" maxlength="2"/></td>
	  <td><input type="text" name="formatCount33_3" id="formatCount33_3" size="2" maxlength="2"/></td>
	  <td><input type="text" name="formatCount33_4" id="formatCount33_4" size="2" maxlength="2"/></td>
	</tr>
   </table>  
    <p><input type="button" onClick="doSave(this.form);" value="Create Items" />&nbsp; <span id="progress_spinner">&nbsp;</span></p>
END_HERE
#end here
    if ($buildTable) {

      my $rootId = "";
      for ( my $i = 1 ; $i <= 6 ; $i++ ) {

        if ( $params->{"type${i}"} == $HD_AREA ) {
          $rootId = $params->{"hdId${i}"};
          last;
        }
      }

      $hd = &getStandardsUnderRoot( $dbh, $rootId );

      $psgi_out .= <<END_HERE;
      <table border="1" cellspacing="2" cellpadding="2">
        <tr>
          <th>Location</th>
	  <th>Standard</th>
	  <th width="40%">Description</th>
END_HERE

      foreach ( sort { $a <=> $b } keys %{ $const[$OC_ITEM_FORMAT] } ) {
        $psgi_out .= '<th>' . $const[$OC_ITEM_FORMAT]->{$_} . '</th>';
      }

      $psgi_out .= '</tr>';

      $psgi_out .= &printStandardsAtLevel($rootId);

      my $itemWriterDisplay =
          &hashToSelect( 'itemWriter', $editors, '4856', '', '', 'value',
            'font-size:11px;' );

      $psgi_out .= <<END_HERE;
    </table> 
		<br />
    <table border="0" cellpadding="2" cellspacing="2">
      <tr>
        <td><span class="text">Assigned Writer:</span></td><td>${itemWriterDisplay}</td>
      </tr>
   </table>   
    <p><input type="button" onClick="doSave();" value="Create Items" />&nbsp; <span id="progress_spinner">&nbsp;</span></p>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}


sub getNextIdList {

    my $id = shift;

    return $id if $hd->{$id}->{type} == $HD_SS_CONTENT;
    return unless defined $hd->{$id}->{child};

    my @idList = ();

    foreach ( sort { $hd->{$a}->{posn} <=> $hd->{$b}->{posn} }
        @{ $hd->{$id}->{child} } )
    {
        push @idList, &getNextIdList($_);
    }

    return @idList;
}

sub printStandardsAtLevel {
  my $psgi_out = '';

  my $hd_id = shift;
  my @header = @_;

  if($hd->{$hd_id}{type} == $HD_SS_CONTENT) {

    # This is root-level so we print the item assignment row

    my $header_string =  join (' / ', grep { defined($_) } @header);
    my $val_string = $hd->{$hd_id}{value};
    my $desc_string = $hd->{$hd_id}{text};

    $psgi_out .= <<HTML;
    <tr>
      <td>${header_string}</td>
      <td>${val_string}</td>
      <td>${desc_string}</td>
HTML

    foreach ( sort { $a <=> $b } keys %{ $const[$OC_ITEM_FORMAT] } ) {

      $psgi_out .= '<td><input type="text" size="3" name="formatCount'  . $hd_id . '_' . $_ . '" /></td>';
    }

    $psgi_out .= '</tr>';

  } elsif ($hd->{$hd_id}{child}) {

    foreach my $child_hd_id (sort { $hd->{$a}{posn} <=> $hd->{$b}{posn} } @{$hd->{$hd_id}{child}}) {

      $psgi_out .= &printStandardsAtLevel($child_hd_id, @header, $hd->{$hd_id}{value});
      
    }
  }

  return $psgi_out;
}
1;