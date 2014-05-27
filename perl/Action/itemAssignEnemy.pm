package Action::itemAssignEnemy;

use ItemConstants;
use Item;
use Data::Dumper;
use HTML::Entities;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $thisUrl = "${orcaUrl}cgi-bin/itemAssignEnemy.pl";
  
  our $OC_ITEM_ENEMY = 52;
  our $HD_LEAF = 6;
  
  our $sth;
  our $sql;
  our %labels = ();
  our %types = ();
  our @levels = []; # holds the values and labels for each standard node
  our %enemy_list = ();
  our %search_list = ();
  
  $in{myAction} = '' unless defined $in{myAction};
  $in{itemNameMatch} = '' unless defined $in{itemNameMatch};
  
  # get the global info if we dont have it
  
  unless(exists $in{itemBankId}) {
  
    $sql = <<SQL;
    SELECT ib.*, sh.hd_id 
      FROM item_bank AS ib, standard_hierarchy AS sh, item AS i
      WHERE i.i_id=$in{itemId}
        AND i.ib_id=ib.ib_id
        AND ib.sh_id=sh.sh_id
SQL
  
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    if(my $row = $sth->fetchrow_hashref) {
  
      $in{itemBankId} = $row->{ib_id};
      $in{hierarchyId} = $row->{sh_id};
      $in{hierarchyName} = $row->{sh_name};
      $in{parent0} = $row->{hd_id};
      $in{level} = 0;
  
    } else {
  
      return [ $q->psgi_header('text/html'), 
               [ &html_die('Unable to locate Standards for this Item Bank') ]];
    }
  }
  
  # do any add/remove actions before getting related data
  
  if($in{myAction} eq 'addEnemy') {
  
    $sql = <<SQL;
    INSERT INTO item_characterization SET i_id=$in{itemId}, ic_type=$OC_ITEM_ENEMY, ic_value=$in{itemEnemyId}
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    $sql = <<SQL;
    INSERT INTO item_characterization SET i_id=$in{itemEnemyId}, ic_type=$OC_ITEM_ENEMY, ic_value=$in{itemId}
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    my $process = $dbh->quote('Item Create/Edit');
    my $detail = $dbh->quote('Assign Item Enemy');
  
    $sql = <<SQL;
    INSERT INTO user_action_item SET i_id=$in{itemId}, u_id=$user->{id}, uai_process=${process}, uai_detail=${detail}
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
  }
  
  if($in{myAction} eq 'removeEnemy') {
  
    $sql = <<SQL;
    DELETE FROM item_characterization WHERE i_id=$in{itemId} AND ic_type=$OC_ITEM_ENEMY AND ic_value=$in{itemEnemyId}
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    $sql = <<SQL;
    DELETE FROM item_characterization WHERE i_id=$in{itemEnemyId} AND ic_type=$OC_ITEM_ENEMY AND ic_value=$in{itemId}
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    my $process = $dbh->quote('Item Create/Edit');
    my $detail = $dbh->quote('Remove Item Enemy');
  
    $sql = <<SQL;
    INSERT INTO user_action_item SET i_id=$in{itemId}, u_id=$user->{id}, uai_process=${process}, uai_detail=${detail}
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
  }
  
  # build the list of item enemies
  $sql = <<SQL;
  SELECT i.i_id, i.i_external_id 
    FROM item AS i, item_characterization AS ic
    WHERE ic.i_id=$in{itemId}
      AND ic.ic_type=$OC_ITEM_ENEMY
      AND ic.ic_value=i.i_id
SQL
  
  $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {
  
    my $key = $row->{i_id};
  
    $enemy_list{$key} = $row->{i_external_id};
  }
  
  # build the list of labels
  
  $sql = "SELECT * FROM qualifier_label WHERE sh_id=$in{hierarchyId}";
  $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {
    $labels{$row->{ql_type}} = $row->{ql_label};
  }
  
  # build standards list for each level
  
  for( my $i=0; $i <= $in{level}; $i++) {
  
    $levels[$i] = [];
  
    my $j = 0;
  
    my $iMinus = $i - 1;
  
    $sql = 'SELECT * FROM hierarchy_definition WHERE hd_parent_id=' 
         . ($i == 0 ? $in{parent0} : $in{"levelSelection$iMinus"})
         . ' ORDER BY hd_posn_in_parent';
    $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my $row = $sth->fetchrow_hashref ) {
      $levels[$i][$j] = {};
      $levels[$i][$j]->{key} = $row->{hd_id};
      $levels[$i][$j]->{name} = $row->{hd_value};
      $levels[$i][$j]->{description} = $row->{hd_std_desc};
  
      $types{$i} = $row->{hd_type};
  
      $j++;
    }
  }
  
  if($in{myAction} eq 'search') {
  
    my $standardMatch = $dbh->quote($in{standardMatch});
  
    # also include a name match if specified
  
    my $sqlItemNameMatch = '';
    
    if($in{itemNameMatch} ne '') {
  
      my $itemNameMatch = $dbh->quote($in{itemNameMatch});
      $itemNameMatch =~ s/^'//;
      $itemNameMatch =~ s/'$//;
   
      $sqlItemNameMatch = <<SQL;
      AND (i.i_external_id LIKE '\%${itemNameMatch}\%' 
           OR i.i_external_id LIKE '${itemNameMatch}\%' 
  	 OR i.i_external_id = '${itemNameMatch}')
SQL
      
    }
  
    if($in{standardMatch} eq '') {
  
      # only match on the name
      $sql = <<SQL;
      SELECT i.i_id, i.i_external_id FROM item AS i
        WHERE i.ib_id=$in{itemBankId}
        AND i.i_id != $in{itemId}
        ${sqlItemNameMatch}
        AND i.i_id NOT IN (SELECT ic_value FROM item_characterization WHERE i_id=$in{itemId} AND ic_type=$OC_ITEM_ENEMY)
        AND i.i_id NOT IN (SELECT i_id FROM item_characterization WHERE ic_type=$OC_ITEM_ENEMY AND ic_value=$in{itemId})
      LIMIT 100
SQL
  
    } else {
  
      # match on the name and the standard
  
      $sql = <<SQL;
      SELECT i.i_id, i.i_external_id FROM item AS i, item_characterization AS ic
        WHERE i.ib_id=$in{itemBankId}
        AND i.i_id != $in{itemId}
        AND i.i_id = ic.i_id
        AND ic.ic_type=$OC_ITEM_STANDARD
        AND ic.ic_value=$standardMatch
        $sqlItemNameMatch
        AND i.i_id NOT IN (SELECT ic_value FROM item_characterization WHERE i_id=$in{itemId} AND ic_type=$OC_ITEM_ENEMY)
        AND i.i_id NOT IN (SELECT i_id FROM item_characterization WHERE ic_type=$OC_ITEM_ENEMY AND ic_value=$in{itemId})
      LIMIT 100
SQL
    }
  
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    #warn $sql;
  
    while(my $row = $sth->fetchrow_hashref) {
  
      my $key = $row->{i_id};
      $search_list{$key} = $row->{i_external_id};
    }
    $sth->finish;
  
  }
 
  return [ $q->psgi_header('text/html'), [ &print_display_enemy_select() ]];
}
### ALL DONE! ###

sub print_display_enemy_select {
  my $psgi_out = '';

  my $jsData = '';

  if($types{$in{level}} == $HD_LEAF) {

    $jsData = <<HTML;
    var leafTextArray = new Array();
    leafTextArray[""] = '';
HTML
    
    foreach my $node (@{$levels[$in{level}]}) {

      my $text = $node->{description};
      $text =~ s/'/\\'/g;
      $text =~ s/\r/\\r/g;
      $text =~ s/\n/\\n/g;
      $text = decode_entities($text);

      $jsData .= "leafTextArray['$node->{key}'] = '$text';\n";

    }
  }

  my $documentReadyFunction = '$("#viewTable").tablesorter();' . "\n";

  if(scalar keys %enemy_list) {

    $documentReadyFunction .= '$("#enemyTable").tablesorter();' . "\n";

  }

  $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
	  <title>Assign Item Enemy</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="JavaScript">
    <!--

      \$(document).ready(function()
			  {
          $documentReadyFunction
        }
      );

      $jsData

      function doSave(id)
      {
        document.itemForm.submit();
	      return true;
      }

      function doSelectLevel(selectObj, selectedLevel) {

        if(selectObj.selectedIndex == 0) { return; }

        /* alert('Select Level = ' + selectedLevel 
	     + ', Index = ' + selectObj.selectedIndex 
	     + ', Value = ' + selectObj.options[selectObj.selectedIndex].value);
        */

        document.itemForm.level.value = selectedLevel + 1;
	document.itemForm.submit();
      }

      function doSearchByName() {

        if(document.itemForm.itemNameMatch.value == '') {
	  alert('Please enter a name to search for.');
	  return 0;
	}

        document.itemForm.myAction.value = 'search';
	document.itemForm.submit();
      }

      function doSearchByStandard(selectObj) {

        if(selectObj.selectedIndex == 0) { return; }

        document.itemForm.myAction.value = 'search';
        document.itemForm.standardMatch.value = selectObj.options[selectObj.selectedIndex].value;
	document.itemForm.submit();
      }

      function doShowLeafText(selectObj) {

	var leafVal = selectObj.options[selectObj.selectedIndex].value;
        document.itemForm.leafText.value = leafTextArray[leafVal];	
      }

      function doItemView (name) {

        document.viewForm.itemBankId.value=$in{itemBankId};
        document.viewForm.itemExternalId.value=name;
        document.viewForm.submit();
      }

      function doAddItemEnemy (id) {

        document.itemForm.myAction.value = 'addEnemy';
	document.itemForm.itemEnemyId.value = id;
        document.itemForm.submit();
      }

      function doRemoveItemEnemy (id) {

        document.itemForm.myAction.value = 'removeEnemy';
	document.itemForm.itemEnemyId.value = id;
        document.itemForm.submit();
      }

    //-->
    </script>
  </head>
  <body>

    <div class="title">Assign Item Enemy</div>
END_HERE

  if(scalar keys %enemy_list) {
    $psgi_out .= <<END_HERE;
   <p>Current Enemy List:</p>
   <table id="enemyTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2">
     <thead>
     <tr>
       <th width="40%">Item</th>
       <th width="30%">View</th>
       <th width="30%">Remove</th>
     </tr>
     </thead>
     <tbody>
END_HERE

    foreach my $id (sort { $enemy_list{$a} cmp $enemy_list{$b} } keys %enemy_list) {
    
      $psgi_out .= <<END_HERE;
        <tr>
	  <td>$enemy_list{$id}</td>
	  <td><input type="button" value="View" onClick="doItemView('$enemy_list{$id}');" /></td>
	  <td><input type="button" value="Remove" onClick="doRemoveItemEnemy($id);" /></td>
        </tr>
END_HERE
    }

    $psgi_out .= '</tbody></table><br />';

  } else {

  $psgi_out .= <<END_HERE;
   <p>No Enemy Items are Assigned.</p>
END_HERE

  }

  $psgi_out .= <<END_HERE;

  <form action="itemPrintList.pl" method="post" name="viewForm" id="item_view" target="_blank">
    <input type="hidden" name="myAction" value="print" />
    <input type="hidden" name="viewType" value="4" />
    <input type="hidden" name="itemBankId" value="" />
    <input type="hidden" name="itemExternalId" value="" />
    <input type="hidden" name="view_itemId" value="1" />
    <input type="hidden" name="view_itemContent" value="1" />
  </form>

    <form name="itemForm" action="${thisUrl}" method="POST">
      <input type="hidden" name="itemId" value="$in{itemId}" />
      <input type="hidden" name="itemBankId" value="$in{itemBankId}" />
      <input type="hidden" name="hierarchyId" value="$in{hierarchyId}" />
      <input type="hidden" name="hierarchyName" value="$in{hierarchyName}" />
      <input type="hidden" name="parent0" value="$in{parent0}" />
      <input type="hidden" name="level" value="$in{level}" />
      <input type="hidden" name="myAction" value="" />
      <input type="hidden" name="standardMatch" value="" />
      <input type="hidden" name="itemEnemyId" value="" />

    <h4>Item Enemy Search</h4>

    <table border="1" cellpadding="2" cellspacing="2" class="no-style">
      <tr>
        <td>Item Name:</td>
	<td><input type="text" name="itemNameMatch" size="30" value="$in{itemNameMatch}" /></td>
      </tr>
      <tr>
        <td colspan="2" align="left"><input type="button" value="Search" onClick="doSearchByName();" /></td>
      </tr>
      <tr>
        <td colspan="2" align="left">And/Or Search by Standard:</td>
      </tr>
END_HERE

  my $i = 0;

  while ( $i <= $in{level} ) {

    my $label = $labels{$types{$i}};
    
    my $onChangeFunction = ($types{$i} == $HD_LEAF)
                         ? "doSearchByStandard(document.itemForm.levelSelection$i);"
			 : "doSelectLevel(document.itemForm.levelSelection$i,$i);";

    $psgi_out .= <<HTML;
    <tr><td>$label</td>
        <td><select name="levelSelection$i" onChange="$onChangeFunction"><option value="">Select One</option>
HTML

    foreach my $node (@{$levels[$i]}) {
       $psgi_out .= '<option value="' . $node->{key} . '"' 
           . ( defined($in{"levelSelection$i"}) && $in{"levelSelection$i"} == $node->{key} ? ' SELECTED ' : '' )
           . '>' . $node->{name} . '</option>'; 
    }

    $psgi_out .= '</select></td></tr>';

#      $psgi_out .= <<HTML;
#      <tr>
#        <td>Text:</td>
#	<td><textarea name="leafText" rows="5" cols="40"></textarea></td>
#      </tr>
#HTML

    $i++;
  }
  
  $psgi_out .= '</table><br />';

  if(scalar keys %search_list) {

    $psgi_out .= <<HTML;
    <p>Item Search</p>
    <table id="viewTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2">
     <thead>
     <tr>
       <th width="40%">Item</th>
       <th width="30%">View</th>
       <th width="30%">Add Enemy</th>
     </tr>
     </thead>
     <tbody>
HTML

    foreach my $id (sort { $search_list{$a} cmp $search_list{$b} } keys %search_list) {

      $psgi_out .= <<END_HERE;
        <tr>
	  <td>$search_list{$id}</td>
	  <td><input type="button" value="View" onClick="doItemView('$search_list{$id}');" /></td>
	  <td><input type="button" value="Add" onClick="doAddItemEnemy($id);" /></td>
        </tr>
END_HERE
    }

    $psgi_out .= '</tbody></table>';

  } else {

    if(defined $in{"levelSelection${HD_LEAF}"} || $in{itemNameMatch} ne '') {
      $psgi_out .= '<p style="color:red;">No Items were found matching the search criteria</p><br />';
    }
  }

  $psgi_out .= '</form></body></html>';

  return $psgi_out;
}


sub html_die {

  my $msg = shift;

  return <<HTML;
  <html>
    <head>
      <title>Error</title>
    </head>
    <body>
       <h3>${msg}</h3>
    </body>
  </html>
HTML
}
1;
