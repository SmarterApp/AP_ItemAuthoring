package Action::passageSetManage;

use ItemConstants;
use File::Glob ':glob';
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/passageSetManage.pl";
  
  our $sth;
  our $sql;
  
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and $user->{adminType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ]];
  }
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};
  $in{passageSetId}  = '' unless exists $in{passageSetId};
  
  our $passageSets = &getPassageSets( $in{itemBankId} );
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome() ]];
  }
  
  if ( $in{myAction} eq 'addPassageSet' ) {
  
    $sql = "SELECT * FROM passage_set WHERE ib_id=$in{itemBankId} AND ps_name="
         . $dbh->quote( $in{passageSetName} );
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( $sth->fetchrow_hashref ) {
       $in{errorMsg} = "<b>Passage Cluster '$in{passageSetName}' already exists.</b>";
       return [ $q->psgi_header('text/html'), [ &print_welcome() ]];
    }
  
    $sql = "INSERT INTO passage_set SET ib_id=$in{itemBankId}, ps_name="
         . $dbh->quote( $in{passageSetName} )
         . ", ps_description=" . $dbh->quote( $in{passageSetDescription} );
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    $in{passageSetId} = $dbh->{mysql_insertid};
  
    # refresh the passageSet list
    $passageSets = &getPassageSets( $in{itemBankId} );
  
  } elsif ( $in{myAction} eq 'addPassage') {
  
    # first, make sure this passage is not in the set
  
    $sql = 'SELECT psl_id FROM passage_set_list WHERE ps_id=' . $in{passageSetId} . ' AND p_id=' . $in{passageId};
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( $sth->fetchrow_hashref ) {
       $in{errorMsg} = "<b>The selected passage is already in this passage set.</b>";
       return [ $q->psgi_header('text/html'), [ &print_edit_passageSet() ]];
    }
  
    # next, figure out the sequence of this passage in the set
  
    my $nextSequence = 1;
  
    $sql = 'SELECT psl_sequence FROM passage_set_list WHERE ps_id=' . $in{passageSetId} . ' ORDER BY psl_sequence DESC LIMIT 1';
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
      $nextSequence = $row->{psl_sequence} + 1; 
    }
  
    # finally, add it to the set
   
    $sql = 'INSERT INTO passage_set_list SET ps_id=' . $in{passageSetId} . ', p_id=' . $in{passageId} . ', psl_sequence='
         . $nextSequence;
    $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
  
    # refresh the passageSet list
    $passageSets = &getPassageSets(  $in{itemBankId} );
  
  } elsif ( $in{myAction} eq 'removePassage') {
  
    my $curSequence = 1;
  
    $sql = 'SELECT pil_sequence FROM passage_set_list WHERE ps_id=' . $in{passageSetId} . ' AND p_id=' . $in{passageId};
    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ( my $row = $sth->fetchrow_hashref ) {
      $curSequence = $row->{pil_sequence}; 
    }
   
    $sql = 'DELETE FROM passage_set_list WHERE ps_id=' . $in{passageSetId} . ' AND p_id=' . $in{passageId};
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    $sql = 'UPDATE passage_set_list SET psl_sequence = psl_sequence - 1 WHERE ps_id=' . $in{passageSetId} . ' AND psl_sequence > ' . $curSequence;
    $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
  
    # refresh the passageSet list
    $passageSets = &getPassageSets(  $in{itemBankId} );
  
  } elsif ( $in{myAction} eq 'movePassage' ) {
  
  }

  return [ $q->psgi_header('text/html'), [ &print_edit_passageSet() ]];
}
### ALL DONE! ###

sub print_welcome {

# Let the user select an item bank and a passageSet, or add a passageSet to the item bank

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;
    my $itemBankHtml =
      &hashToSelect( 'itemBankId', \%itemBanks, $in{itemBankId},
        'changeItemBank();','','','width:200px;');

    my %passageSetHash = map { $_ => $passageSets->{$_}{name} } keys %$passageSets;
    my $passageSetHtml =
      &hashToSelect( 'passageSetId', \%passageSetHash, $in{passageSetId}, '', '', 'value', 'width:200px;' );

    my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
	  <script language="JavaScript">

      function changeItemBank() {
			  document.form1.myAction.value = '';
				document.form1.submit();
			}	
		
		  function editPassageSetSubmit() {
			  document.form1.myAction.value = 'editPassageSet';
				document.form1.submit();
			}

			function addPassageSetSubmit(f) {
			    if(f.itemBankId.selectedIndex == 0) {
				alert('Please enter a Program before saving.');
				f.itemBankId.focus();
				return false;
			    }
			    if(f.passageSetName.value.match(/^\\s*\$/) ) {
				alert('Please enter a Passage Name before saving.');
				f.passageSetName.focus();
				return false;
			    }
			    f.myAction.value = 'addPassageSet';
			    f.submit();
			}

		</script>
  </head>
  <body>
	<div class="title">Passage Cluster Management</div>
	${errorHtml}
	<form name="form1" action="${thisUrl}" method="POST">
	  
	  <input type="hidden" name="myAction" value="" />
	<table border="0" cellpadding="3" cellspacing="3" class="no-style">
	  <tr><td><span class="text"><font color="red">Program:<font></span></td>
		    <td>${itemBankHtml}</td>
		</tr>
		<tr>
		  <td><span class="text">Edit Passage Cluster:</span></td>
			<td>${passageSetHtml}&nbsp;&nbsp;
			    <input type="button" value="Edit" onClick="editPassageSetSubmit();" /></td>
		</tr>
		<tr>
		  <td colspan="2">OR</td>
		</tr>
		<tr>
		  <td colspan="2"><span class="text">Add Passage Cluster</span></td>
                </tr>
		<tr>
		  <td><font color="red">Name:<font></td><td><input type="text" size="20" name="passageSetName" /></td>
                </tr>
		<tr>
		  <td>Description:</td><td><input type="text" size="50" name="passageSetDescription" /></td>
                </tr>
		<tr>
		  <td colspan="2"><span style="color:red;">Red label</span> = required field</td>
		</tr>	
		<tr>
		  <td colspan="2"><input type="button" value="Add" onClick="addPassageSetSubmit(this.form);" /></td>
		</tr>	
	</table>
	</form>
	</body>
</html>	
END_HERE
}

sub print_edit_passageSet {
  my $psgi_out = '';

    my $itemBankName = $banks->{ $in{itemBankId} }{name};
    my $errorHtml    = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );

    my $passageSet = $passageSets->{$in{passageSetId}};

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
		<script language="JavaScript">
		  
			
			function viewPassage(id) {
			  document.passageView.passageId.value = id;
          		document.passageView.submit();
			}

			function removePassage(id) {
			  document.form1.passageId.value = id;
			  document.form1.myAction.value = 'removePassage';
          		document.form1.submit();
			}

			function addPassage(id) {
			  document.form1.passageId.value = id;
			  document.form1.myAction.value = 'addPassage';
          		document.form1.submit();
			}

		</script>
	</head>
	<body>
	<div class="title">Edit Passage Cluster</div>
	${errorHtml}
	<form name="passageView" action="${orcaUrl}cgi-bin/passageView.pl" method="POST" target="_blank">
	  
	  <input type="hidden" name="passageId" value="" />
	</form>
	<form name="form1" action="${thisUrl}" method="POST">
	  
	  <input type="hidden" name="myAction" value="" />
		<input type="hidden" name="writerId" value="" />
		<input type="hidden" name="passageSetId" value="$in{passageSetId}" />
		<input type="hidden" name="itemBankId" value="$in{itemBankId}" />
		<input type="hidden" name="passageId" value="" />
	<table border="0" cellpadding="3" cellspacing="3" class="no-style">
	  <tr><td><span class="text">Program:</span></td>
		    <td>${itemBankName}</td>
		</tr>
		<tr>
		  <td><span class="text">Passage Cluster:</span></td>
			<td>$passageSet->{name}</td>
		</tr>
		<tr>
		  <td><span class="text">Description:</span></td>
			<td>$passageSet->{description}</td>
		</tr>
  </table>
	<br />
	<span class="text">Passages</span>
	<table border="1" cellpadding="3" cellspacing="3">
    <tr>
		  <th>Name</th><th>View</th><th>Remove</th>
		</tr>
END_HERE

    foreach my $passageId ( @{$passageSet->{passages}} ) {
    
      my $passage = new Passage($dbh, $passageId);

      $psgi_out .= <<END_HERE;
      <tr>
        <td>$passage->{name}</td>
	<td><input type="button" name="view_passage" value="View" onClick="viewPassage($passageId);" /></td>
	<td><input type="button" name="remove_passage" value="Remove" onClick="removePassage($passageId);" /></td>
      </tr>	
END_HERE

    }

    my $passageListHtml =
      &hashToSelect( 'addPassageId',
        &getPassageItemSets( $in{itemBankId} ),
        '', '', '', 'value', 'width:200px;' );

  $psgi_out .= <<END_HERE;
  </table>
  <br />
  <table border="0" cellpadding="3" cellspacing="3" class="no-style">
     <tr>
       <td>Add Passage:</td>
       <td>${passageListHtml}</td>
       <td><input type="button" name="add_passage" value="Add" 
               onClick="addPassage(document.form1.addPassageId.options[document.form1.addPassageId.selectedIndex].value);" />
       </td>
     </tr>
   </table>
  </form>
 </body>
</html>	
END_HERE

  return $psgi_out;
}

sub getPassageItemSets {

 my $itemBankId = shift || 0;

 my %passages = ();
 my $sql = <<SQL;
 SELECT * FROM passage 
   WHERE ib_id=${itemBankId}
SQL

  my $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {

    $passages{$row->{p_id}} = $row->{p_name};
  }
  $sth->finish;

  return \%passages;
}

sub getPassageSets {

  my $itemBankId = shift || 0;
  my %passageSets   = ();

  my $sql = "SELECT * FROM passage_set WHERE ib_id=${itemBankId}";
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {

    $passageSets{ $row->{ps_id} } = {};
    $passageSets{ $row->{ps_id} }{name} = $row->{ps_name};
    $passageSets{ $row->{ps_id} }{description} = $row->{ps_description};
    $passageSets{ $row->{ps_id} }{passages} = [];

    $sql = 'SELECT * FROM passage_set_list WHERE ps_id=' . $row->{ps_id} . ' ORDER BY psl_sequence';
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute();

    while( my $row2 = $sth2->fetchrow_hashref) {

      push @{$passageSets{ $row->{ps_id} }{passages}}, $row2->{p_id}; 
    }
    $sth2->finish;

  }
  $sth->finish;

  return \%passageSets;
  
}
1;
