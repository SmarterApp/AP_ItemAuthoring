package Action::itemView;

use URI::Escape;
use ItemConstants;
use Item;
use Rubric;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  
  our $this_url = "${orcaUrl}cgi-bin/itemView.pl";

  our $sth;
  our $sql;

  # Authorize user (must be user type UT_ITEM_EDITOR and have some permissions)
  our $user = Session::getUser($q->env,$dbh);
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  our $isAdmin = $user->{adminType} ? 1 : 0;
  
  unless ( defined $in{itemExternalId} ) {
    $in{message} = "Please enter an Item ID";

    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
  }

  $in{itemExternalId} =~ tr/./_/;
  
  if ( $in{itemExternalId} =~ m/\*/ ) {
  
    $in{itemExternalId} =~ s/\*/%/g;
    $sql =
          "SELECT i_external_id FROM item WHERE ib_id=$in{itemBankId}"
        . ' AND i_external_id LIKE '
        . $dbh->quote( $in{itemExternalId} );
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    my @itemList = ();
    while ( my $row = $sth->fetchrow_hashref ) {
        push @itemList, $row->{i_external_id};
    }
    $in{itemExternalId} = join( ' ', @itemList );
  
  }
  
  # First, grab any items defined explicitly
  our @itemIds = split( / /, $in{itemExternalId} );
  
  # Next, add any items specified in an upload file
  if ( defined $in{myfile} ) {
  
    my $uploadHandle = $q->upload("myfile");
  
    open UPLOADED, ">/tmp/itemlist.$$.txt";
  
    while (<$uploadHandle>) {
        print UPLOADED;
    }
    close UPLOADED;
  
    open ITEMLIST, "</tmp/itemlist.$$.txt";
  
    while (<ITEMLIST>) {
        $_ =~ s/\s+$//;
        next if $_ =~ /^Item/;
        last if $_ eq '';
  
        my @fields = split /,/, $_;
        push( @itemIds, shift @fields ) if $_ ne '';
    }
    close ITEMLIST;
  
    unlink("/tmp/itemlist.$$.txt");
  
    $in{itemExternalId} = join( ' ', @itemIds );
  }
  
  $in{total} = @itemIds;
  unless ( defined $in{step} ) {
      $in{step} = 0;
  }
  
  if ( $in{step} >= $in{total} ) {
      $in{step} = $in{total} - 1;
  }
  if ( $in{step} < 0 ) {
      $in{step} = 0;
  }
  $in{currentExternalId} = $itemIds[ $in{step} ];
  
  $sql =
      "SELECT i_id FROM item WHERE i_external_id="
    . $dbh->quote( $in{currentExternalId} )
    . " AND ib_id=$in{itemBankId} ORDER BY i_version DESC LIMIT 1";
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  if ( my $row = $sth->fetchrow_hashref ) {
      $in{itemId} = $row->{i_id};
  }
  else {
    $in{message} = "Item '$in{currentExternalId}' Not Found. Try Again.";

    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ] ];
  }
  
  return [ $q->psgi_header('text/html'), [ &print_preview(\%in) ] ];
}

### ALL DONE! ###

sub print_welcome {

    my $params = shift;
    my $msg    = (
        defined( $params->{message} )
        ? "<div style='color:#ff0000;'>" . $params->{message} . "</div>"
        : "" );

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

    my $defaultBank =
      ( defined $params->{itemBankId} ? $params->{itemBankId} : "0" );
    my $ibankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $defaultBank, '', '' );

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>Item Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
    <!--
      function myOpen(name,url,w,h)
      {
	var myWin = window.open(url,name,'width='+w+',height='+h+',resizable=yes,scrollbars=yes,toolbar=no,location=no,directories=no,status=no,menubar=no,copyhistory=no');
        myWin.moveTo(370,180);
	return true;
      }

      function findByStandardUrl(url)
      {
        return url + '?itemBankId=' + document.itemFindStandard.itemBankId.value;
      }
    //-->
    </script>
  </head>
  <body>
    <div class="title">Item Viewer</div>
    <p>${msg}</p>
    <form name="itemView" action="itemView.pl" method="POST" enctype="multipart/form-data" target="_blank">
     <input type="hidden" name="actionType" value="preview" />
						 
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr><td><span class="text">Program:</span></td><td>${ibankDisplay}</td></tr> 
      <tr>
        <td><span class="text">ID:</span></td>
        <td><input type="text" class="long-value" name="itemExternalId" />&nbsp;&nbsp;
         <input type="submit" value="View" />
        </td>
      </tr>
			<tr><td colspan="2"><b>AND/OR</b></td></tr>
			<tr>
			  <td><span class="text">Upload File:</span></td>
				<td><input type="file" name="myfile" /></td></tr>
    </table>
    </form>
    <div style="margin-left:10px;"><b>OR</b></div>
    <form name="itemFindStandard" action="" method="GET">
    <table border="0" cellspacing="2" cellpadding="2" class="no-style">  
      <tr><td><span class="text">Program:</span></td><td>${ibankDisplay}</td>
      <td><input type="button" value="Find By Standard" onClick="document.location.href='${findByStandardUrl}?itemBankId=' + document.itemFindStandard.itemBankId.value;" /></td></tr>
   </table> 
   </form>
  </body>
</html>         
END_HERE
}

sub print_preview {
  my $psgi_out = '';

    my $params = shift;

    my $item = new Item( $dbh, $params->{itemId} );
    my $c = $item->getDisplayContent();

    my $currentId      = $params->{currentExternalId};
    my $currentIdSafe  = uri_escape($currentId);
    my $formatName       = $item_formats{ $item->{format} } || '';
    my $difficultyName = $difficulty_levels{ $item->{difficulty} } || '';
    my $devStateName   = $dev_states{ $item->{devState} };

    my $gle = $item->getGLE();
    my $gleName = ( defined $gle->{name} ? $gle->{name} : '' );
    $gleName =~ s/GLE//;
    my $gleText = ( defined $gle->{text} ? $gle->{text} : '' );
    $gleText =~ s/\r?\n/<br \/>/g;

    my $charDisplay = "";

    foreach (@ctypes) {
        $charDisplay .=
            '<tr><td>'
          . $labels[$_] . '</td>'
          . '<td><b>'
          . $const[$_]->{ $item->{$_} }
          . '</b></td></tr>';
    }

    # Here's where we manage the step selection
    my $step        = $params->{step} + 1;
    my $stepTotal   = $params->{total};
    my $backStep    = $params->{step} - 1;
    my $refreshStep = $step - 1;

    my $stepSelect =
'<select name="step" onChange="document.itemSelectForm.submit();"><option value="" SELECTED></option>';

    for ( my $i = 0 ; $i < $stepTotal ; $i++ ) {
        $stepSelect .= '<option value="' . $i . '">' . ( $i + 1 ) . '</option>';
    }
    $stepSelect .= '</select>';

    my $cssInclude = $item->getCssLink() . "\n";

    # Now print the HTML
    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <title>SBAC IAIP Item Viewer</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link href="${orcaUrl}style/item-style.css" rel="stylesheet" type="text/css">
    ${cssInclude}
    <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
    <script type="text/javascript" src="${commonUrl}mathjax/MathJax.js?config=MML_HTMLorMML"></script>
  </head>
  <body>
    <div class="title">Item Viewer</div>
    <table class="no-style" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td style="width:93px;">Item ${step} of ${stepTotal}</td>
  <td valign="bottom" style="vertical-align:bottom;">
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
						 
             <input type="hidden" name="step" value="${refreshStep}" />
             <input style="margin-top:15px;vertical-align:bottom;" type="submit" value="Refresh" />
           </form>
	   </td>
	   <td>&nbsp;&nbsp;</td>
        <td>
END_HERE

    if ($isAdmin) {
        $psgi_out .= <<END_HERE;
		<a href="javascript://" onClick="window.opener.parent.frames['rightFrame'].location='${itemCreateUrl}?itemBankId=$params->{itemBankId}&externalId=${currentIdSafe}&myAction=edit';window.opener.parent.frames['rightFrame'].focus();" />Open in Item Editor</a>
END_HERE
    }
    else {
        $psgi_out .= '&nbsp;';
    }

    $psgi_out .= <<END_HERE;
	       </td>
         <td>&nbsp;&nbsp;</td><td><a href="${this_url}">View Other Items</a></td>
      </tr> 
    </table>
    <br />
    <table class="no-style" border="0" cellspacing="0" cellpadding="0">
      <tr>
END_HERE

    if ( $backStep >= 0 ) {
        $psgi_out .= <<END_HERE;
	  <td>
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
             <input type="hidden" name="step" value="${backStep}" />
						 
             <input type="submit" value="Back" />
           </form>
	   </td>
	   <td>&nbsp;&nbsp;</td>
END_HERE
    }

    if ( $step < $in{total} ) {
        $psgi_out .= <<END_HERE;
	<td>
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
             <input type="hidden" name="step" value="${step}" />
						 
             <input type="submit" value="Next" />
           </form>
	   </td>
END_HERE
    }

    $psgi_out .= <<END_HERE;
  <td>&nbsp;&nbsp;</td>
  <td>
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
             <input type="hidden" name="step" value="0" />
						 
             <input type="submit" value="First Item" />
           </form>
	   </td>
  <td>&nbsp;&nbsp;</td>
  <td>
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
             <input type="hidden" name="step" value="${stepTotal}" />
						 
             <input type="submit" value="Last Item" />
           </form>
	   </td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td>
           <form name="itemSelectForm" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
						 
             Select: ${stepSelect} 
	   </form>
	   </td>
  </tr>
</table>

END_HERE

    if ( $gleName ne '' ) {
        $psgi_out .= <<END_HERE
     <table class="no-style" border="1" cellspacing="2" cellpadding="2">
       <tr><th align="center">GLE ${gleName}</th></tr>
       <tr><td>${gleText}</td></tr>
     </table>
     <br />
END_HERE
    }

    if ( $item->{reviewLock} eq '1' && $item->{reviewLifetime} ge &get_ts() ) {
        $psgi_out .= <<END_HERE
	  <p><b>Locked for Review:</b> Until $c->{reviewLifetime} PST</p>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    <p>Item:&nbsp;&nbsp;<b>${currentId}</b>&nbsp;&nbsp;&lt;$item->{bankName}&gt;<br />
    Description:&nbsp;&nbsp;$item->{description}</p>
    $c->{itemBody}
    <br />
    $c->{distractorRationale}
    <br />
    $c->{correctResponse}
    <br />
    <table border="1" cellspacing="3" cellpadding="2">
     <tr><td>Item Format:</td><td><b>${formatName}</b></td></tr> 
     ${charDisplay}
     <tr><td>Dev State:</td><td><b>${devStateName}</b></td></tr>
     <tr><td>Difficulty:</td><td><b>${difficultyName}</b></td></tr>
     </table>
		 <br />
END_HERE

    foreach ( @{ $item->{rubrics} } ) {
        my $rubric = new Rubric( $dbh, $_ );
        $psgi_out .= <<END_HERE;
    <table width="500px;" border="1" cellspacing="3" cellpadding="3">
		  <tr><td align="center">Rubric: $rubric->{name}</td></tr>
			<tr><td>$rubric->{content}</td></tr>
		</table>
		<br />
END_HERE
    }

    $psgi_out .= <<END_HERE;
     <table class="no-style" border="0" cellspacing="2" cellpadding="2">
       <tr>
         <td>Item ${step} of ${stepTotal}</td>
	 <td>&nbsp;&nbsp;</td>
END_HERE

    if ( $backStep >= 0 ) {
        $psgi_out .= <<END_HERE;
	<td>
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
             <input type="hidden" name="step" value="${backStep}" />
						 
             <input style="margin-top:15px;" type="submit" value="Back" />
           </form>
	   </td>
END_HERE
    }

    if ( $step < $in{total} ) {
        $psgi_out .= <<END_HERE;
	<td>
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
             <input type="hidden" name="step" value="${step}" />
						 
             <input style="margin-top:15px;" type="submit" value="Next" />
           </form>
	   </td>
END_HERE
    }

    $psgi_out .= <<END_HERE;
  <td>&nbsp;&nbsp;</td>
  <td>
           <form name="itemView" action="itemView.pl" method="POST">
             <input type="hidden" name="itemExternalId" value="$params->{itemExternalId}" />
             <input type="hidden" name="itemBankId" value="$params->{itemBankId}" />
             <input type="hidden" name="step" value="${refreshStep}" />
						 
             <input style="margin-top:15px;" type="submit" value="Refresh" />
           </form>
	   </td>
       </tr>
     </table>
     <table class="no-style" border="0" cellspacing="2" cellpadding="2">
       <tr>
        <td>
END_HERE

    if ($isAdmin) {
        $psgi_out .= <<END_HERE;
		<a href="javascript://" onClick="window.opener.parent.frames['rightFrame'].location='${itemCreateUrl}?itemBankId=$params->{itemBankId}&externalId=${currentIdSafe}&myAction=edit';window.opener.parent.frames['rightFrame'].focus();" />Open in Item Editor</a>
END_HERE
    }
    else {
        $psgi_out .= '&nbsp;';
    }

    $psgi_out .= <<END_HERE;
       </td> 
			 <td>&nbsp;&nbsp;</td> 
       <td>
         <a href="${this_url}">View Other Items</a>
       </td></tr>
     </table>  
  </body>
</html>         
END_HERE

  return $psgi_out;
}
1;
