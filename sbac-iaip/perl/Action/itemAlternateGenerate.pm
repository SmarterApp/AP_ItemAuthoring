package Action::itemAlternateGenerate;

use ItemConstants;
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
  
  our %ia_adaptation_type = ( 0 => 'None',
                          1 => 'Audio',
  			2 => 'Tactile',
  			3 => 'Text',
  			4 => 'Visual' );
  
  our %ia_representation_form = ( 0 => 'None',
                                 1 => 'Enhanced',
  			       2 => 'Verbatim',
  			       3 => 'Reduced',
  			       4 => 'Real-time',
  			       5 => 'Transcript' );
  
  our %ia_language = ( '' => 'None',
                      'ar' => 'Arabic',
  		      'zh-yu' => 'Cantonese',
  		      'en' => 'English',		      
		      'ilo' => 'Ilokano',
  		      'ko' => 'Korean',
  		      'zh-cm' => 'Mandarin',
  		      'pa' => 'Punjabi',
  		      'ru' => 'Russian',
              'es' => 'Spanish',
  		      'tl' => 'Tagalog',
  		      'uk' => 'Ukrainian',
  		      'vi' => 'Vietnamese' );
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{itemBank} = (keys %$banks)[0] unless $in{itemBank};
  
  unless ( $user->{type} == $UT_ITEM_EDITOR
      and ( $user->{adminType} || $user->{reviewType} == $UR_CONTENT_SPECIALIST ) )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ]];
  }
  
  $in{myAction} = '' unless exists $in{myAction};
  
  our $editors = &getEditors($dbh, $in{itemBank});
  
  if ( $in{myAction} eq '' ) {
 
    return [ $q->psgi_header('text/html'), [ &print_first_screen(\%in) ]];
  }
  elsif ( $in{myAction} eq 'create' ) {
  
    my @itemList = ();
    my %itemsCreatedList = ();
    my %itemsWithErrorList = ();
  
    my $writerCode = '';
    $sql = "SELECT * FROM user WHERE u_id = " . $in{assignedWriter};
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
        $writerCode = $row->{u_writer_code};
    }
  
    if($in{myfile} =~ /\.(.*?)$/) {
      my $ext = $1;
  
      if($ext ne 'TXT' && $ext ne 'CSV' && $ext ne 'txt' && $ext ne 'csv') {
        $in{message} = 'Please use plain-text or CSV upload file format';

	return [ $q->psgi_header('text/html'), [ &print_first_screen(\%in) ]];
      }
    }
  
    my $uploadHandle = $q->upload("myfile");
  
    while (<$uploadHandle>) {
  
       $_ =~ s/\s+//g; 
       last if $_ eq '';
  
       push @itemList, $_;
    }
  
    my $itemsCreated = 0;
  
    foreach my $originalItemName (@itemList) {
  
        my $oItem = new Item($dbh, $in{itemBank}, $originalItemName); 
  
        if($oItem->{id} == 0) {
          $itemsWithErrorList{$originalItemName} = "Item not found";
          next;
        }
  
        my $prefix = $oItem->getNamePrefix($in{itemBank}, 1, $writerCode);
        my $seq = sprintf('%04d', &getNextItemSequence($dbh, $in{itemBank}, $prefix));
        my $newName = $prefix . $seq;
  
        my $copyStatus = $oItem->copy( $newName );
  
        if($copyStatus !~ /^Copied/) {
          $itemsWithErrorList{$originalItemName} = $copyStatus;
  	next;
        }
  
        $itemsCreatedList{$originalItemName} = $newName;
      
        my $item = new Item($dbh, $in{itemBank}, $newName);
  
        $item->setAuthor( $in{assignedWriter} );
        $item->setDueDate( $in{dueDate} );
        $item->setLanguage( $in{language} );
        $item->setPublicationStatus( $in{publicationStatus} );
  
        $item->save('Item Alternate Generator', $user->{id}, 'Created Item');
  
        my $alt_lang_safe = $dbh->quote($in{adaptedLanguage});
        my $alt_label_safe = $dbh->quote($in{alternateLabel});
  
        $sql = <<SQL;
        INSERT INTO item_alternate
         SET i_id=$oItem->{id},
             ia_alternate_i_id=$item->{id},
  	   ia_adaptation_type=$in{adaptationType},
  	   ia_representation_form=$in{representationForm},
  	   ia_language=${alt_lang_safe},
  	   ia_alternate_label=${alt_label_safe}
SQL
        $sth = $dbh->prepare($sql);
        $sth->execute();
  
        $itemsCreated++;
    }
    
    # Send e-mail to writer that they have items, if they have items
  
    if($itemsCreated) {
  
      my $notification_status = &sendNewItemNotification($dbh,$banks->{$in{itemBank}}{name}, $in{assignedWriter});
      $in{message} = 'Unable to send e-mail notification to item assignee.' unless $notification_status;
    }
 
    return [ $q->psgi_header('text/html'),
             [ &print_report( \%in, \@itemList, \%itemsCreatedList, 
	                      \%itemsWithErrorList, $itemsCreated ) ]];
  }
}
### ALL DONE! ###

sub print_report {
  my $psgi_out = '';

  my $params   = shift;
  my $itemList = shift;
  my $itemsCreatedList = shift;
  my $itemsWithErrorList = shift;
  my $itemCount = shift;

  my $itemBankName = $banks->{ $params->{itemBank} }{name};
  my $editorName   = $editors->{ $params->{assignedWriter} };

  my $msg = defined($in{message}) ? '<div style="color:red;">' . $in{message} . '</div>' : '';

  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Alternate Creation Report</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
  </head>
  <body>
    <div class="title">Created ${itemCount} New Items</div>
    ${msg}
    <p>Program: ${itemBankName}
END_HERE

  if($itemCount) {

    $psgi_out .= <<END_HERE;
    <br />
    Assigned To: ${editorName}</p>
    <p>Items Created:</p>
    <table border="1" cellspacing="2" cellpadding="2">
      <tr><td>Original</td><td>Alternate</td></tr>
END_HERE

    foreach my $originalItemName (@{$itemList}) {

      if(exists $itemsCreatedList->{$originalItemName}) {

        $psgi_out .= <<HTML;
        <tr>
          <td>$originalItemName</td>
	  <td>$itemsCreatedList->{$originalItemName}</td>
        </tr>
HTML
      }
    }

    $psgi_out .= <<END_HERE;
    </table>
    <br />
END_HERE

  }

  if(scalar keys %{$itemsWithErrorList}) {
    $psgi_out .= <<END_HERE;
    <br />
    <p>Items With Error:</p>
    <table border="1" cellspacing="2" cellpadding="2">
      <tr><td>Item</td><td>Status</td></tr>
END_HERE

    foreach my $originalItemName (@{$itemList}) {

      if(exists $itemsWithErrorList->{$originalItemName}) {
        $psgi_out .= <<HTML;
        <tr>
          <td>$originalItemName</td>
	  <td>$itemsWithErrorList->{$originalItemName}</td>
        </tr>
HTML

      } 
    }

    $psgi_out .= <<END_HERE;
    </table>
    <br />
END_HERE
  }

  $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_first_screen {

    my $params = shift;

    my $msg = defined($in{message}) ? '<div style="color:red;">' . $in{message} . '</div>' : '';

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $itemBankHtml =
      &hashToSelect( 'itemBank', \%itemBanks, $params->{itemBank}, 'changeItemBank();',
        '', '', 'font-size:11px;' );

    my $languageHtml = &hashToSelect('language',\%languages, $params->{language} || 1,'','');

    my $adaptationTypeHtml = &hashToSelect('adaptationType', \%ia_adaptation_type,
                                           $params->{adaptationType} || 0, '', '', 'font-size:11px;');

    my $representationFormHtml = &hashToSelect('representationForm', \%ia_representation_form, 
                                                $params->{representationForm} || 0, '', '', 'font-size:11px;');
  
    my $adaptedLanguageHtml = &hashToSelect('adaptedLanguage', \%ia_language, 
                                      $params->{adaptedLanguage} || '', '', '', 'font-size:11px;');

    my $editorHtml = &hashToSelect('assignedWriter', $editors, '', '', '', 'font-size:11px');
    
    my $publicationStatusHtml =
      &hashToSelect( 'publicationStatus', \%publication_status,
        $params->{publicationStatus} || 0, '', 'null', '', 'width:100px;' );

    my $dueDate = $params->{dueDate} || '';
    my $alternateLabel = $params->{alternateLabel} || '';

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>SBAC IAIP Item Alternate Creation</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
        <script src="${commonUrl}js/calendar/cal2.js" type="text/javascript"></script>
    <script language="JavaScript">
    <!--
      
      function mySubmit()
      {

        if(document.itemCreate.itemBank.selectedIndex == 0) {

	  alert('Please select a Program.');
	  return false;
	}

        if(document.itemCreate.dueDate.value == '') {
	  alert('Please enter a Due Date.');
	  return false;
	}

        if(document.itemCreate.alternateLabel.value == '') {
	  alert('Please enter an Alternate Label.');
	  return false;
	}

	if(document.itemCreate.myfile.value == '') {
	  alert('Please select an Upload File.');
	  return false;
	}

	document.itemCreate.myAction.value = 'create';
	document.itemCreate.submit();
        return true; 
      }

      function changeItemBank() {
        document.itemCreate.myAction.value = '';
	document.itemCreate.submit();
	return true;
      }	

      addCalendar("calendar1", "Select Date", "dueDate", "itemCreate");
      setWidth(90, 1, 15, 1);
      setFormat("yyyy-mm-dd");


    //-->
    </script>
  </head>
  <body>
    <div class="title">Create New Item Alternates</div>
    ${msg}
    <form name="itemCreate" action="itemAlternateGenerate.pl" method="POST" enctype="multipart/form-data">
      <input type="hidden" name="myAction" value="create" />
      
    <table border="0" cellpadding="4" cellspacing="4">
      <tr><td><span class="required">Program:</span></td><td>${itemBankHtml}</td></tr>
      <tr><td><span>Language:</span></td><td>${languageHtml}</td></tr>
      <tr><td><span>Publication Status:</span></td><td>${publicationStatusHtml}</td></tr>
      <tr><td><span class="requireed">Assigned Writer:</span></td><td>${editorHtml}</td></tr>
      <tr><td><span class="required">Due Date:</span></td>
          <td>
           <input type="text" id="dueDate" name="dueDate" size="11" value="$dueDate" readonly="readonly" onclick="javascript:showCal('calendear1')" />
           &nbsp;<a href="javascript:showCal('calendar1')">Select Date</a>
       <div id="calendar1"></div>
    </td>
    </tr>
    <tr><td>Adaptation Type:</td><td>${adaptationTypeHtml}</td></tr>
    <tr><td>Representation Form:</td><td>${representationFormHtml}</td></tr>
    <tr><td>Adapted Language:</td><td>${adaptedLanguageHtml}</td></tr>
    <tr><td><span class="required">Alternate Label:</span></td><td><input type="text" name="alternateLabel" size="40" value="$alternateLabel" /></td></tr>
    <tr><td><span class="required">Upload File:</span></td><td><input type="file" name="myfile" /></td></tr> 
      <tr><td colspan="2"><input type="button" name="save" value="Create Items" onClick="mySubmit();" />
    </table>
    <p>Note: The Upload File should have one Item ID per line, in plain-text or CSV format.</p>
    </form>
  </body>
</html>
END_HERE
}
1;
