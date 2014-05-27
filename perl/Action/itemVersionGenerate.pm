package Action::itemVersionGenerate;

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
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{itemBank} = (keys %$banks)[0] unless $in{itemBank};
  
  unless ( $user->{type} == $UT_ITEM_EDITOR and $user->{adminType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ]];
  }
  
  $in{myAction} = '' unless exists $in{myAction};
  
  our $editors = &getEditors($dbh, $in{itemBank});
  
  if ( $in{myAction} eq '' ) {
 
    return [ $q->psgi_header('text/html'), [ &print_first_screen(\%in) ]];
  
  } elsif ( $in{myAction} eq 'confirm' ) {
  
    my @itemList = ();
    my @itemsNotFoundList = ();
    my @itemsFoundList = ();
  
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
  
    foreach my $itemName (@itemList) {
  
      my $testItem = new Item($dbh, $in{itemBank}, $itemName);
  
      if($testItem->{id}) {
        push @itemsFoundList, $itemName;
      } else {
        push @itemsNotFoundList, $itemName;
      }
    }
 
    return [ $q->psgi_header('text/html'), 
             [ &print_confirmation( \@itemsFoundList, \@itemsNotFoundList ) ]];
  
  } elsif ( $in{myAction} eq 'create' ) {
  
    my @itemList = split /\|/, $in{itemList};
  
    foreach my $itemName (@itemList) {
  
      # get an object for the item to version
      my $item = new Item($dbh, $in{itemBank}, $itemName);
  
      if($item->{id}) {
  
        $item->version();
  
        # Get an object for the new version
        my $newItem = new Item($dbh, $in{itemBank}, $itemName);
  
        if($newItem->{id}) {
  
          $newItem->setAuthor( $in{assignedWriter} );
          $newItem->setDueDate( $in{dueDate} );
  
          $newItem->save('Item Version Generator', $user->{id}, 'Created Item Version');
        }
      }
  
    }
    
    # Send e-mail to writer that they have items
  
    my $notification_status = &sendNewItemNotification($dbh, $banks->{$in{itemBank}}{name}, $in{assignedWriter});
    $in{message} = 'Unable to send e-mail notification to item assignee.' unless $notification_status;
 
    return [ $q->psgi_header('text/html'), [ &print_report( \@itemList ) ]];
  }
}
### ALL DONE! ###

sub print_report {
  my $psgi_out = '';

    my $itemList = shift;

    my $itemCount = scalar( @{$itemList} );

    my $itemBankName = $banks->{ $in{itemBank} }{name};
    my $editorName   = $editors->{ $in{assignedWriter} };

    my $msg = defined($in{message}) ? '<div style="color:red;">' . $in{message} . '</div>' : ''; 

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Version Report</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
  </head>
  <body>
    <div class="title">Created ${itemCount} New Item Versions</div>
    ${msg}
    <p>
    Program: ${itemBankName}<br />
    Assigned To: ${editorName}<br />
    Due Date: $in{dueDate} 
    </p>
    <p>Items Versioned:</p>
    <table border="1" cellspacing="2" cellpadding="2">
END_HERE

    for (my $i = 0; $i < $itemCount; $i++) {

      $psgi_out .= <<HTML;
      <tr>
        <td>$itemList->[$i]</td>
      </tr>
HTML
    }

    $psgi_out .= <<END_HERE;
    </table>
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_confirmation {
  my $psgi_out = '';

  my $itemsFoundList = shift;
  my $itemsNotFoundList = shift;

  my $itemsFoundCount = scalar( @{$itemsFoundList} );
  my $itemsNotFoundCount = scalar( @{$itemsNotFoundList} );

  my $itemBankName = $banks->{ $in{itemBank} }{name};
  my $editorName   = $editors->{ $in{assignedWriter} };

  my $itemListString = join ('|', @{$itemsFoundList});

  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Version Confirmation Report</title>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <script type="text/javascript">
      function doConfirm() {
        document.itemCreate.submit();
      }

      function doCancel() {
        document.itemCreate.myAction.value = '';
        document.itemCreate.itemList.value = '';
        document.itemCreate.dueDate.value = '';
	document.itemCreate.submit();
      }
    </script>
  </head>
  <body>
    <form name="itemCreate" action="itemVersionGenerate.pl" method="POST">
      <input type="hidden" name="myAction" value="create" />
      
      <input type="hidden" name="itemList" value="${itemListString}" />
      <input type="hidden" name="assignedWriter" value="$in{assignedWriter}" />
      <input type="hidden" name="itemBank" value="$in{itemBank}" />
      <input type="hidden" name="dueDate" value="$in{dueDate}" />
    <div class="title">Confirm ${itemsFoundCount} New Item Versions</div>
    <p>Program: ${itemBankName}</p>
    Assigned To: ${editorName}
    <br />
    Due Date: $in{dueDate} 
    <br />
END_HERE

  if($itemsFoundCount) { 

    $psgi_out .= <<HTML;
    <input type="button" value="Confirm" onClick="doConfirm();" />&nbsp&nbsp;&nbsp;
    <input type="button" value="Cancel" onClick="doCancel();" />&nbsp&nbsp;&nbsp;
    <p>Items To Be Versioned:</p>
    <table border="1" cellspacing="2" cellpadding="2">
HTML

    foreach (@{$itemsFoundList}) {

      $psgi_out .= <<HTML;
      <tr><td>$_</td></tr>
HTML
    }

    $psgi_out .= '</table><br />';
  } else {

    $psgi_out .= '<p>No Items were found to Version!</p>';
  }

  if($itemsNotFoundCount) { 

    $psgi_out .= <<HTML;
    <p>Items Not Found:</p>
    <table border="1" cellspacing="2" cellpadding="2">
HTML

    foreach (@{$itemsNotFoundList}) {

      $psgi_out .= <<HTML;
      <tr><td>$_</td></tr>
HTML
    }

    $psgi_out .= '</table><br />';
  }

  $psgi_out .= <<END_HERE;
    </form>
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub print_first_screen {

    my $msg = defined($in{message}) ? '<div style="color:red;">' . $in{message} . '</div>' : ''; 

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $itemBankHtml =
      &hashToSelect( 'itemBank', \%itemBanks, $in{itemBank}, 'changeItemBank();',
        '', '', 'font-size:11px;' );

    my $editorHtml = &hashToSelect('assignedWriter', $editors, '', '', '', 'font-size:11px');
    

    my $dueDate = $in{dueDate} || '';

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="${orcaUrl}style/text.css" />
    <title>Item Version Creation</title>
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

	if(document.itemCreate.myfile.value == '') {
	  alert('Please select an Upload File.');
	  return false;
	}

	document.itemCreate.myAction.value = 'confirm';
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
    <div class="title">Create New Item Versions</div>
		${msg}
    <form name="itemCreate" action="itemVersionGenerate.pl" method="POST" enctype="multipart/form-data">
      <input type="hidden" name="myAction" value="confirm" />
      
    <table border="0" cellpadding="4" cellspacing="4">
      <tr><td><span class="required">Program:</span></td><td>${itemBankHtml}</td></tr>
      <tr><td>Assigned Writer:</td><td>${editorHtml}</td></tr>
      <tr><td><span class="required">Due Date:</span></td>
          <td>
           <input type="text" id="dueDate" name="dueDate" size="11" value="$dueDate" />
           &nbsp;<a href="javascript:showCal('calendar1')">Select Date</a>
       <div id="calendar1"></div>
    </td>
    </tr>
    <tr><td><span class="required">Upload File:</span></td><td><input type="file" name="myfile" /></td></tr> 
      <tr><td colspan="2"><input type="button" name="save" value="Create Item Versions" onClick="mySubmit();" />
    </table>
    <p>Note: The Upload File must have one Item ID per line, and the Upload File filename extension must be TXT or CSV.</p>
    </form>
  </body>
</html>
END_HERE
}
1;
