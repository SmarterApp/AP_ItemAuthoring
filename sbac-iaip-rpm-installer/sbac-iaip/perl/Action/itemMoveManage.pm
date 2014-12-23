package Action::itemMoveManage;

use ItemConstants;
use Item;
use Data::Dumper;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $this_url = "${orcaUrl}cgi-bin/itemMoveManage.pl";
  
  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};

  our $shareData = &getShareData($in{itemBankId});
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%in) ]];
  }
  
  our $dataIsOkay     = 1;
  our @movedItems    = ();
  
  #
  # Handle either the 'upload' or 'save' case
  #
  if ( $in{myAction} eq 'save' ) {
  
      &do_db_update();
      unlink( $in{uploadFile} );
  
      return [ $q->psgi_header('text/html'), [ &print_save_page() ]];
  }
  elsif ( $in{myAction} eq 'upload' ) {
  
      my $uploadHandle = $q->upload("myfile");
      $in{uploadFile} = "/tmp/itemdataupload.$$.txt";
  
      open UPLOADED, ">$in{uploadFile}";
      while (<$uploadHandle>) {
          print UPLOADED;
      }
      close UPLOADED;
 
      my $psgi_out = &print_confirm_header();
  
      open ITEMLIST, "<$in{uploadFile}";
  
      # validate that these items exist in the source bank and don't exist in the target bank

      $sql = 'SELECT i_id FROM item WHERE ib_id=? AND i_external_id=?';
      my $sth = $dbh->prepare($sql);

      while (<ITEMLIST>) {
          $_ =~ s/\s+$//;
          last if $_ eq '';

          $sth->execute($in{itemBankId}, $_);

	  $psgi_out .= '<tr><td>';

	  if($sth->fetchrow_hashref) {

            $sth->execute($in{targetProgram}, $_);

	    if($sth->fetchrow_hashref) {
	      $dataIsOkay = 0;
              $psgi_out .= '<span style="color:red;">' . $_ . '</span> (Target)';
	    } else {
	      $psgi_out .= $_;
	      push @movedItems, $_;
            }
          } else {
	    $dataIsOkay = 0;
            $psgi_out .= '<span style="color:red;">' . $_ . '</span> (Source)';
	  }
  
          $psgi_out .= '</td></tr>'; 
      }
  
      close ITEMLIST;
  
      unless ($dataIsOkay) {
          unlink( $in{uploadFile} );
      }
  
      $psgi_out .= &print_confirm_footer();

      return [ $q->psgi_header('text/html'), [ $psgi_out ]];
  }
}
### ALL DONE! ###

sub do_db_update {

  open ITEMLIST, "<$in{uploadFile}";

  while (<ITEMLIST>) {
    $_ =~ s/\s+$//;
    last if $_ eq '';

    my $item = new Item($dbh, $in{itemBankId}, $_); 
    $item->moveToBank($in{targetProgram}, 'Item Move', $user->{id}, 'Moved between Programs'); 

    push @movedItems, $_;
  }

  close ITEMLIST;
}

sub print_welcome {
  my $psgi_out = '';

  my $params = shift;

  my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;

  my $ibankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $in{itemBankId}, 'doReload();', '',
        'value' );

  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Item Move</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
    <script language="JavaScript">

    function doSubmit() {
            if( document.itemMove.myfile.value.match(/^\\s*\$/) ) {
                alert( 'Please select a file to upload.' );
                document.itemMove.myfile.focus();
                return false;
            }
	    document.itemMove.submit();
    }	

			function doReload() {
			  document.itemMove.myAction.value = '';
				document.itemMove.submit();
			}

		</script>
	</head>
  <body>
    <div class="title">Item Move</div>
    <form name="itemMove" action="${this_url}" method="POST" enctype="multipart/form-data">
     <input type="hidden" name="myAction" value="upload" />
    <table border="0" cellspacing="3" cellpadding="3" class="no-style">
      <tr><td><span class="text">Source Program:</span></td><td>${ibankDisplay}</td></tr>
			<tr><td><span class="text">Upload File:</span></td><td><input type="file" name="myfile" /></td></tr> 
    </table>
    <br />
END_HERE

  if(scalar keys %{$shareData}) {
    $psgi_out .= <<END_HERE;
    Target Program:
    <br />
    <table border="1" cellspacing="2" cellpadding="2">
      <tr>
        <td>Select</td><td>Organization</td><td>Program</td>
      </tr>
END_HERE

    foreach my $ib_key (keys %{$shareData}) {
      $psgi_out .= <<END_HERE;
      <tr>
        <td><input type="radio" name="targetProgram" value="$ib_key"></td>
	<td>$shareData->{$ib_key}{orgName}</td>
	<td>$shareData->{$ib_key}{bankName}</td>
      </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    </table>
    <p><input type="button" value="Move Items" onClick="doSubmit();" /></p>
END_HERE
  } else {
    $psgi_out .= '<p>The selected Program has no other Programs to move items to.</p>';
  }

  $psgi_out .= <<END_HERE;
        </td>
      </tr>
    </table>
    </form>
		<br />
		<h4><span class="text">Instructions:</span></h4>
		<ul>
		<li>First select the Source Program, which contains the items that will be moved. Then, select the 
		   Target Program, where the items will be moved to.
		</li>
		<li>You will receive a full listing of the potential changes to be made, so that you may correct
		   any errors before completing the update.
		</li>
		<li>If the Source Program does not contain and Item with the Item ID being moved, 
		   the Item ID will be displayed
			 in <span style="color:red;">red</span>, and the move process will be unable to complete.
		</li>
		<li>If the Target Program contains an Item with the same Item ID as
		   one that is being moved, the Item ID will be displayed
			 in <span style="color:red;">red</span>, and the move process will be unable to complete.
		</li>	 
		</ul>
  </body>
</html>         
END_HERE

  return $psgi_out;
}

sub print_confirm_header {

    my $sourceBankName = $banks->{ $in{itemBankId} }{name};
    my $targetBankName = $shareData->{ $in{targetProgram} }{bankName};

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Item Move</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">

      function doSubmit() {
				document.itemMove.submit();
			}	

		</script>
	</head>
  <body>
    <div class="title">Item Move Summary</div>
    <p><b>Source Program:</b>&nbsp;${sourceBankName}</p> 
    <p><b>Target Program:</b>&nbsp;${targetBankName}</p> 
		<form name="itemMove" action="${this_url}" method="POST">
     <input type="hidden" name="myAction" value="save" />
     <input type="hidden" name="itemBankId" value="$in{itemBankId}" />
     <input type="hidden" name="targetProgram" value="$in{targetProgram}" />
     <input type="hidden" name="uploadFile" value="$in{uploadFile}" />
		<table border="1" cellspacing="3" cellpadding="1">
END_HERE
}

sub print_confirm_table_header {
    return '<tr><th>'
      . '</th></tr>';
}

sub print_confirm_footer {
  my $psgi_out = '';

    $psgi_out .= '</table>';

    if ($dataIsOkay && scalar(@movedItems)) {
        $psgi_out .= <<END_HERE;
		<br />
		<input type="button" value="Save These Changes" onClick="document.itemMove.submit();" />
		<br />
END_HERE
    }
    else {
        $psgi_out .= <<END_HERE;
		<br />
		<input type="button" value="Upload New File" onClick="document.location.href='${thisUrl}?itemBankId=$in{itemBankId}';" />
    <br />	
END_HERE
    }

    $psgi_out .= '</form>';

    $psgi_out .= '</body></html>';
  return $psgi_out;
}

sub print_save_page {
  my $psgi_out = '';

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Item Move</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
	</head>
  <body>
    <div class="title">Items Moved</div>
END_HERE

    if ( scalar @movedItems ) {
        $psgi_out .= '<p><b>Moved these Items:</b></p><ul><li>'
          . join( '</li><li>', @movedItems ) . '</ul>';
    }

    $psgi_out .= <<END_HERE;
  </body>
</html>
END_HERE

  return $psgi_out;
}

sub getShareData {

  my $bankId = shift;

  my %out = ();

  $sql = <<SQL;
  SELECT ib.ib_external_id, ib.ib_id, o.o_name
    FROM item_bank AS ib, organization AS o, item_bank_share AS ibs
    WHERE ibs.ibs_ib_share_id=${bankId}
      AND ibs.ib_id=ib.ib_id
      AND ib.o_id=o.o_id
SQL

  $sth = $dbh->prepare($sql);
  $sth->execute();

  while(my $row = $sth->fetchrow_hashref) {
    my $key = $row->{ib_id};
    $out{$key}{bankName} = $row->{ib_external_id};
    $out{$key}{orgName} = $row->{o_name};
  }

  return \%out;
}
1;
