package Action::workgroupManage;

use ItemConstants;
use File::Copy;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $thisUrl = "${orcaUrl}cgi-bin/workgroupManage.pl";
  our @workGroupFields = ($OC_CONTENT_AREA, $OC_GRADE_LEVEL);
  
  # Authorize user (must be user type UT_ITEM_EDITOR and be an admin)
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and $user->{adminType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ];
  }
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};
  
  $in{myAction} = '' unless exists $in{myAction};

  our $workGroups = &getWorkgroups($dbh, $in{itemBankId});
  $in{workGroupId} = (keys %$banks)[0] unless exists($in{workGroupId}) || scalar(keys %$workGroups) == 0;
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
  }
  
  if ( $in{myAction} eq 'addWorkGroup' ) {
  
      my $sql = "SELECT * FROM workgroup WHERE w_name="
        . $dbh->quote( $in{workGroupName} );
      my $sth = $dbh->prepare($sql);
      $sth->execute();
      if ( $sth->fetchrow_hashref ) {
        $in{errorMsg} = "Program '$in{workGroupName}' already exists.";
	return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
      }
  
      # Create the 'workgroup' record
  
      $sql = sprintf('INSERT INTO workgroup SET w_name=%s, ib_id=%d, w_description=\'\'',
          $dbh->quote( $in{workGroupName} ),
	  $in{itemBankId});
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      $in{workGroupId} = $dbh->{mysql_insertid};
  
      # refresh the workgroup list
      $workGroups = &getWorkgroups($dbh, $in{itemBankId});
  
      return [ $q->psgi_header('text/html'), [ &print_edit_workgroup() ] ];
  }
  elsif ( $in{myAction} eq 'editWorkGroup' ) {
    return [ $q->psgi_header('text/html'), [ &print_edit_workgroup() ] ];
  }
  elsif ( $in{myAction} eq 'addFilter' ) {

    my $sql = sprintf('INSERT INTO workgroup_filter SET w_id=%d', $in{workGroupId});
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    my $wf_id = $dbh->{mysql_insertid};

    foreach my $field (@workGroupFields) {
      $sql = sprintf('INSERT INTO workgroup_filter_part SET wf_id=%d, wf_type=%d, wf_value=%d',
                     $wf_id, $field, $in{"filterField${field}"});
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    return [ $q->psgi_header('text/html'), [ &print_edit_workgroup() ] ];
  }
  elsif ( $in{myAction} eq 'deleteFilter' ) {

    my $sql = sprintf('DELETE FROM workgroup_filter_part WHERE wf_id=%d', $in{filterId});
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    $sql = sprintf('DELETE FROM workgroup_filter WHERE wf_id=%d', $in{filterId});
    $sth = $dbh->prepare($sql);
    $sth->execute();

    $in{errorMsg} = 'Filter Deleted';

    return [ $q->psgi_header('text/html'), [ &print_edit_workgroup() ] ];
  }
  elsif ( $in{myAction} eq 'save' ) {
    my $sql = sprintf('UPDATE workgroup SET w_description=%s WHERE w_id=%d',
                      $dbh->quote($in{description}),
		      $in{workGroupId});
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    # refresh the workgroup list
    $workGroups = &getWorkgroups($dbh, $in{itemBankId});

    $in{errorMsg} = 'Updated Workgroup';

    return [ $q->psgi_header('text/html'), [ &print_edit_workgroup() ] ];
  }

  # rest of actions are related to user assignment

  our $usersInItemBank = &getUsersByItemBank($dbh, $in{itemBankId});

  if ( $in{myAction} eq 'editUsers' ) {

    return [ $q->psgi_header('text/html'), [ &print_assign_users_to_workgroup() ] ];

  }
  elsif ( $in{myAction} eq 'saveUsers' ) {

      # Put all of these statements in a transaction
  
      $dbh->{RaiseError} = 1;
      $dbh->{AutoCommit} = 0;
  
      {
  
          $sql =
  "DELETE FROM user_permission WHERE up_type=${UP_VIEW_WORKGROUP} AND up_value=$in{workGroupId}";
          $sth = $dbh->prepare($sql);
          $sth->execute();
  
          foreach ( grep { $_ =~ /^user/ } keys %in ) {
              $_ =~ /^user_(\d+)/;
              my $userId = $1;
              $sql =
  "INSERT INTO user_permission SET u_id=${userId}, up_type=${UP_VIEW_WORKGROUP}, up_value=$in{workGroupId}";
              $sth = $dbh->prepare($sql);
              $sth->execute();
          }
      };
  
      if ($@) {
          $dbh->rollback();
          $in{errorMsg} = 'Unable to update Workgroup user list';
      }
      else {
          $dbh->commit();
          $in{errorMsg} = 'Updated Workgroup user list';
      }
      $dbh->{AutoCommit} = 1;
  
      $usersInItemBank = &getUsersByItemBank($dbh, $in{itemBankId});
  
      return [ $q->psgi_header('text/html'), [ &print_assign_users_to_workgroup() ] ];
  }
}
### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    # Let the user select a workgroup to edit, or edit a workgroup

    my %bankHash = map { $_ => $banks->{$_}{name} } keys %$banks;
    my $itemBankHtml = &hashToSelect( 'itemBankId', \%bankHash, $in{itemBankId}, 'reloadForm(this.form);', '', 'value' );

    my %wgHash = map { $_ => $workGroups->{$_}{name} } keys %$workGroups;
    my $wgHtml = &hashToSelect( 'workGroupId', \%wgHash, '', '', '', 'value' );


    my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html>
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">

      function reloadForm(f) {
        f.myAction.value = '';
        f.submit();
      }	

	function editWorkGroupSubmit(f) {
		if( f.workGroupId.options[f.workGroupId.selectedIndex].value == '' ) {
		    alert('Please Select a Workgroup to Edit.');
		    f.workGroupId.focus();
		    return false;
		}
		  f.myAction.value = 'editWorkGroup';
			f.submit();
	}

	function assignUserWorkGroupSubmit(f) {
		if( f.workGroupId.options[f.workGroupId.selectedIndex].value == '' ) {
		    alert('Please Select a Workgroup to Assign Users.');
		    f.workGroupId.focus();
		    return false;
		}
		  f.myAction.value = 'editUsers';
			f.submit();
	}

	function addWorkGroupSubmit(f) {
		if( f.workGroupName.value.match(/^\\s*\$/) ) {
	    	    alert('Please Enter a Workgroup Name to Add.');
	    	    f.workGroupName.focus();
	    	    return false;
		}
		f.myAction.value = 'addWorkGroup';
		f.submit();
	}

		</script>
	</head>
	<body>
	<div class="title">Workgroup Management</div>
	${errorHtml}
	<form name="form1" action="${thisUrl}" method="POST">
	  <input type="hidden" name="myAction" value="" />
	<table id="main" border="0" cellpadding="3" cellspacing="3" class="no-style">
	  <tr>
	    <td>Program:</td>
	    <td>${itemBankHtml}</td>
          </tr>
	  <tr>
	    <td>Edit Workgroup:</td>
   	    <td>${wgHtml}</td>
          </tr>
	  <tr>
	    <td colspan="2">
		 <input class="action_button" type="button" value="Edit" onClick="editWorkGroupSubmit(this.form);" />
		 &nbsp;&nbsp;&nbsp;
		 <input class="action_button" type="button" value="Assign Users" onClick="assignUserWorkGroupSubmit(this.form);" />
	    </td>
	  </tr>
		<tr>
		  <td colspan="2">OR</td>
		</tr>
		<tr>
		  <td colspan="2">Add Workgroup</td>
                </tr>
		<tr>
		  <td>Name:</td><td><input class="value-long" type="text" size="20" name="workGroupName" maxlength="50" /></td>
                </tr>
		<tr>
		  <td colspan="2"><input class="action_button" type="button" value="Add" onClick="addWorkGroupSubmit(this.form);" /></td>
		</tr>	
	</table>
	</form>
	</body>
</html>	
END_HERE

  return $psgi_out;
}

sub print_edit_workgroup {
  my $psgi_out = '';

  my %wgHash = map { $_ => $workGroups->{$_}{name} } keys %$workGroups;
  my $wgHtml = &hashToSelect( 'workGroupId', \%wgHash, $in{workGroupId}, 'doWorkGroupSelect();', '', 'value' );

  my $itemBankName = $banks->{$in{itemBankId}}{name};

  my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );
  my $workGroup = $workGroups->{ $in{workGroupId} };

  my $filterSelect = '';

  foreach my $field (@workGroupFields) {
      $filterSelect .= $labels[$field] . ' = '
                     . &hashToSelect('filterField' . $field, $const[$field])
		     . '&nbsp;&nbsp;&nbsp;';
  }

  $psgi_out .= <<END_HERE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script language="JavaScript">
		  
	function doSave(f) {
	  f.myAction.value = 'save';
 	  f.submit();
	}

	function doBack(f) {
	  f.myAction.value = '';
 	  f.submit();
	}

	function doItemBankSelect() {
	  document.form1.myAction.value='editBank';
	  document.form1.submit();
        }

	function doAddFilter(f) {
          f.myAction.value = 'addFilter';
	  f.submit();
	}

	function doDeleteFilter(f, fId) {
          f.myAction.value = 'deleteFilter';
          f.filterId.value = fId;
	  f.submit();
	}

        function showWG() {
	  alert('WG = $workGroup->{name}');
	  alert('Desc = $workGroup->{description}');
        }

    </script>
  </head>
  <body>
    <div class="title">Edit Workgroup</div>
	${errorHtml}
	<form name="form1" action="${thisUrl}" method="POST">
	  <input type="hidden" name="myAction" value="" />
	  <input type="hidden" name="filterId" value="" />
	<table id="main" border="0" cellpadding="3" cellspacing="2" class="no-style">
	  <tr>
	    <td>Program:</td><td>${itemBankName}</td>
          </tr>
	  <tr>
	    <td>Workgroup:</td>
	    <td>${wgHtml}</td>
  	  </tr>
	  <tr>
	    <td>Description:</td>
	    <td><input type="text" name="description" size="40" value="$workGroup->{description}" maxlength="100" /></td>
          </tr>
	  <tr>
	    <td>
	      <input type="button" value="Save" onClick="doSave(this.form);" />
	    </td>
	    <td>
	      <input type="button" value="Back" onClick="doBack(this.form);" />
	    </td>
          </tr>
        </table>
	<br /><br />
	<div class="title">Filters</div>
	<p>New Filter: ${filterSelect}&nbsp;&nbsp;
	  <input type="button" value="Add" onClick="doAddFilter(this.form);" />
	</p>
	<table id="detail" border="1" cellpadding="2" cellspacing="2" >
	  <tr>
END_HERE

  foreach my $field (@workGroupFields) {
    $psgi_out .= '<th>' . $labels[$field] . '</th>';
  }

  $psgi_out .= '<th>Action</th></tr>';

  my $filters = &getWorkgroupFilters($dbh, $in{workGroupId});

  if(scalar keys %{$filters}) {

    foreach my $filterKey (keys %{$filters}) {

      my $filter = $filters->{$filterKey};
      $psgi_out .= '<tr>';

      foreach my $field (@workGroupFields) {
        $psgi_out .= '<td>' . $const[$field]->{$filter->{parts}{$field}} . '</td>';
      }

      $psgi_out .= '<td><input type="button" value="Delete" onClick="doDeleteFilter(this.form,' 
                 . $filterKey . ');" /></td></tr>';
    }

  } else {
    $psgi_out .= '<tr><td colspan="3" align="center">No filters defined for this workgroup.</td></tr>';
  }

  $psgi_out .= '</table></body></html>';

  return $psgi_out;
}

sub print_assign_users_to_workgroup {

  my $psgi_out = '';

  my %wgHash = map { $_ => $workGroups->{$_}{name} } keys %$workGroups;
  my $wgHtml = &hashToSelect( 'workGroupId', \%wgHash, $in{workGroupId}, 'doWorkGroupSelect();', '', 'value' );

  my $itemBankName = $banks->{$in{itemBankId}}{name};

  my $usersInWorkgroup = &getUsersInWorkgroup($in{workGroupId});

  my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );
  my $workGroup = $workGroups->{ $in{workGroupId} };

  $psgi_out .= <<END_HERE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
		<script language="JavaScript">
		  
			function doSaveSubmit() {
			  document.form1.myAction.value = 'saveUsers';
				document.form1.submit();
			}

			function doWorkGroupSelect() {
			  document.form1.myAction.value='editUsers';
				document.form1.submit();
      }

	function doBack(f) {
	  f.myAction.value = '';
 	  f.submit();
	}

		</script>
	</head>
	<body>
	<div class="title">Edit Workgroup Users</div>
	${errorHtml}
	<form name="form1" action="${thisUrl}" method="POST">
	  <input type="hidden" name="myAction" value="" />
	<table id="users" border="0" cellpadding="3" cellspacing="2" class="no-style">
	  <tr>
	    <td>Program:</td>
	    <td>${itemBankName}</td>
          </tr>
	  <tr>
	    <td>Workgroup:</td>
	    <td>${wgHtml}</td>
  	  </tr>
END_HERE

    foreach my $role ( sort { $a <=> $b }  keys %review_type )  {
      $psgi_out .= '<th align="left" width="190px">' . $review_type{$role} . "</th>\n";
    }

    $psgi_out .= '</tr><tr>';

    foreach my $role ( sort { $a <=> $b }  keys %review_type ) 
    {
        $psgi_out .= '<td valign="top">';

        foreach my $key ( sort { $usersInItemBank->{$a}{name} cmp $usersInItemBank->{$b}{name} }
            grep { $usersInItemBank->{$_}{reviewType} == $role } keys %$usersInItemBank )
        {

            my $checked =
              exists( $usersInWorkgroup->{$key} )
              ? 'CHECKED'
              : '';

            $psgi_out .= <<END_HERE;
			   <div style="margin-top:2px;margin-bottom:2px;border-bottom:1px solid black;"><input type="checkbox" name="user_${key}" value="yes" ${checked} />&nbsp;&nbsp;$usersInItemBank->{$key}{name}</div>
END_HERE
        }

        $psgi_out .= '&nbsp;</td>';
    }

    $psgi_out .= '</tr>';

    $psgi_out .= <<END_HERE;
	</table>
	<br />
	<p><input type="button" value="Save" onClick="doSaveSubmit();" />&nbsp&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	      <input type="button" value="Back" onClick="doBack(this.form);" />
	</p>
	</form>
	</body>
</html>	
END_HERE

  return $psgi_out;
}

sub getUsersInWorkgroup {
  my $workGroupId = shift;

  my %users = ();

  my $sql = <<SQL;
  SELECT u_id FROM user_permission WHERE up_type=${UP_VIEW_WORKGROUP} AND up_value=${workGroupId}
SQL
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  while(my $row = $sth->fetchrow_hashref) {
    $users{$row->{u_id}} = 1;
  }
  return \%users;
}
1;
