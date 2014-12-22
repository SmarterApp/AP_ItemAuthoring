package Action::itemBankManage;

use ItemConstants;
use File::Copy;
use JSON;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $thisUrl = "${orcaUrl}cgi-bin/itemBankManage.pl";
  
  # Authorize user (must be user type UT_ITEM_EDITOR and be an admin)
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and $user->{adminType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ] ];
  }
  
  our $bankSelectUser = ($user->{adminType} == $UA_PROGRAM) ? $user->{id} : 0;
  our $bankSelectOrg = ($user->{adminType} == $UA_SUPER) ? 0 : $user->{organizationId};
  our $banks = &getItemBanks($dbh, $bankSelectUser, $bankSelectOrg);
  
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};
  
  our $orgs = &getOrganizations($dbh);
  our %org_label = map { $_ => $orgs->{$_}{name_escaped} } keys %$orgs;
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
  }
  
  our $localOrgId = ($user->{adminType} == $UA_SUPER) 
                    ? ($in{organizationId} ? $in{organizationId} : $banks->{$in{itemBankId}}{organization}) 
		    : $user->{organizationId};

  $in{organizationId} = (keys %$orgs)[0] unless exists $in{organizationId};
  
  our $users = &getUsersWithPermissions($dbh, $localOrgId);
  
  if ( $in{myAction} eq 'addBank' ) {
  
      $in{bankName} =~ s/\s+/_/g;
  
      my $sql = "SELECT * FROM item_bank WHERE ib_external_id="
        . $dbh->quote( $in{bankName} );
      my $sth = $dbh->prepare($sql);
      $sth->execute();
      if ( $sth->fetchrow_hashref ) {
        $in{errorMsg} = "Program '$in{bankName}' already exists.";
	return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
      }
  
      # Create the 'item_bank' record
  
      $sql = sprintf(
  'INSERT INTO item_bank SET ib_external_id=%s, ib_description=\'\', ib_owner=\'\', ib_host_base=\'\', ib_has_ims=0, ib_assign_ims_id=0, o_id=%d',
          $dbh->quote( $in{bankName} ),
  	$localOrgId);
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      my $bankId = $dbh->{mysql_insertid};
  
      # Create the item import user
  
      $sql = sprintf('INSERT INTO user SET u_username=%s, u_password=%s, u_type=11, u_active=1, u_deleted=0, u_permissions=0, o_id=%d, u_first_name=%s, u_last_name=%s, u_email=%s',
                      $dbh->quote($instance_name . $bankId),
  		    $dbh->quote('emptyp@ssw0rd'),
  		    $localOrgId,
  		   $dbh->quote('Item'),
  		   $dbh->quote('Importer'),
  		   $dbh->quote('cde@pacificmetrics.com'));
  
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      my $importerUserId = $dbh->{mysql_insertid};
  
      # Update the 'item_bank' record with the importer user ID
  
      $sql = sprintf('UPDATE item_bank SET ib_importer_u_id=%d WHERE ib_id=%d', $importerUserId, $bankId);
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      # Create the directories that contain data for the item bank
  
      # folder for item images
      mkdir "${orcaPath}images/lib${bankId}", 0777;
      system( 'chmod', 'a+rw', "${orcaPath}images/lib${bankId}" );
  
      # folder for passages
      mkdir "${orcaPath}passages/lib${bankId}", 0777;
      system( 'chmod', 'a+rw', "${orcaPath}passages/lib${bankId}" );
  
      # folder for passage images
      mkdir "${orcaPath}passages/lib${bankId}/images", 0777;
      system( 'chmod', 'a+rw', "${orcaPath}passages/lib${bankId}/images" );
  
      # folder for rubrics
      mkdir "${orcaPath}rubrics/lib${bankId}", 0777;
      system( 'chmod', 'a+rw', "${orcaPath}rubrics/lib${bankId}" );
  
      # folder for rubric images
      mkdir "${orcaPath}rubrics/lib${bankId}/images", 0777;
      system( 'chmod', 'a+rw', "${orcaPath}rubrics/lib${bankId}/images" );
  
      # folder for item history PDF
      mkdir "${orcaPath}item-pdf/lib${bankId}",    0777;
  
      # folder for passage history PDF
      mkdir "${orcaPath}passage-pdf/lib${bankId}", 0777;
  
      # folder for item bank metafiles
      mkdir "${orcaPath}itembank-metafiles/lib${bankId}", 0777;
      system( 'chmod', 'a+rw', "${orcaPath}itembank-metafiles/lib${bankId}" );
  
      # refresh the bank list
      $banks = &getItemBanks($dbh, $bankSelectUser, $bankSelectOrg);
  
      $in{itemBankId} = $bankId;
  
      return [ $q->psgi_header('text/html'), [ &print_edit_bank() ] ];
  }
  elsif ( $in{myAction} eq 'editBank' ) {
    return [ $q->psgi_header('text/html'), [ &print_edit_bank() ] ];
  }
  elsif ( $in{myAction} eq 'save' ) {
  
      # Put all of these statements in a transaction
  
      $dbh->{RaiseError} = 1;
      $dbh->{AutoCommit} = 0;
  
      {
          my $sql = sprintf( 'UPDATE item_bank SET ib_description=%s, ib_owner=%s, ib_host_base=%s, tb_id=%d, sh_id=%d WHERE ib_id=%d',
              $dbh->quote( $in{description} ),
              $dbh->quote( $in{owner} ),
              $dbh->quote( $in{hostBase} ),
  	    exists( $in{tb_id} ) ? $in{tb_id} : 0,
              exists( $in{sh_id} ) ? $in{sh_id} : 0,
              $in{itemBankId}
          );
          my $sth = $dbh->prepare($sql);
          $sth->execute();
  
          $sql =
  "DELETE FROM user_permission WHERE up_type=${UP_VIEW_ITEM_BANK} AND up_value=$in{itemBankId}";
          $sth = $dbh->prepare($sql);
          $sth->execute();
  
          foreach ( grep { $_ =~ /^user/ } keys %in ) {
              $_ =~ /^user_(\d+)/;
              my $userId = $1;
              $sql =
  "INSERT INTO user_permission SET u_id=${userId}, up_type=${UP_VIEW_ITEM_BANK}, up_value=$in{itemBankId}";
              $sth = $dbh->prepare($sql);
              $sth->execute();
          }
      };
  
      if ($@) {
          $dbh->rollback();
          $in{errorMsg} = 'Unable to update Program configuration';
      }
      else {
          $dbh->commit();
          $in{errorMsg} = 'Updated Program configuration';
      }
      $dbh->{AutoCommit} = 1;
  
      $users = &getUsersWithPermissions($dbh, $localOrgId);
      $banks = &getItemBanks($dbh, $bankSelectUser, $bankSelectOrg);
  
      return [ $q->psgi_header('text/html'), [ &print_edit_bank() ] ];
  }
}
### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    # Let the user select an item bank to edit, or add an item bank

    my %bankHash = map { $_ => $banks->{$_}{name} } keys %$banks;
    my $itemBankHtml = &hashToSelect( 'itemBankId', \%bankHash, '', '', '', 'value' );

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

		  function editBankSubmit(f) {
			if( f.itemBankId.options[f.itemBankId.selectedIndex].value == '' ) {
			    alert('Please Select a Program to Edit.');
			    f.itemBankId.focus();
			    return false;
			}
			  f.myAction.value = 'editBank';
				f.submit();
		}

			function addBankSubmit(f) {
				if( f.bankName.value.match(/^\\s*\$/) ) {
			    	    alert('Please Enter a Program Name to Add.');
			    	    f.bankName.focus();
			    	    return false;
				}
				f.myAction.value = 'addBank';
				f.submit();
			}

		</script>
	</head>
	<body>
	<div class="title">Program Management</div>
	${errorHtml}
	<form name="form1" action="${thisUrl}" method="POST">
	  <input type="hidden" name="myAction" value="" />
	<table border="0" cellpadding="3" cellspacing="3" class="no-style">
		<tr>
		  <td><span class="text">Edit Program:</span></td>
			<td>${itemBankHtml}&nbsp;&nbsp;
			    <input class="action_button" type="button" value="Edit" onClick="editBankSubmit(this.form);" /></td>
		</tr>
		<tr>
		  <td colspan="2">OR</td>
		</tr>
		<tr>
		  <td colspan="2"><span class="text">Add Program</span></td>
                </tr>
END_HERE

    if($user->{adminType} == $UA_SUPER) {

      my $orgHtml = &hashToSelect( 'organizationId', \%org_label, '', '', '', '', '');

      $psgi_out .= <<END_HERE;
      <tr>
        <td>Organization:</td>
	<td>${orgHtml}</td>
      </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
		<tr>
		  <td>Name:</td><td><input class="value-long" type="text" size="20" name="bankName" /></td>
                </tr>
		<tr>
		  <td colspan="2"><input class="action_button" type="button" value="Add" onClick="addBankSubmit(this.form);" /></td>
		</tr>	
	</table>
	</form>
	</body>
</html>	
END_HERE

  return $psgi_out;
}

sub print_edit_bank {
  my $psgi_out = '';

    my %bankHash = map { $_ => $banks->{$_}{name} } keys %$banks;
    my $itemBankHtml =
      &hashToSelect( 'itemBankId', \%bankHash, $in{itemBankId},
        'doItemBankSelect();', '', 'value' );

    my $standards = &getStandards($dbh);
    my $standardHtml = &hashToSelect( 'sh_id', $standards, $banks->{$in{itemBankId}}{sh_id}, '', '', 'value' );

    my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );
    my $bank               = $banks->{ $in{itemBankId} };

    $psgi_out .= <<END_HERE;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
		<script language="JavaScript">
		  
			function doSaveSubmit() {
			  document.form1.myAction.value = 'save';
				document.form1.submit();
			}

			function doItemBankSelect() {
			  document.form1.myAction.value='editBank';
				document.form1.submit();
      }

		</script>
	</head>
	<body>
	<div class="title">Edit Program</div>
	${errorHtml}
	<form name="form1" action="${thisUrl}" method="POST">
	  <input type="hidden" name="myAction" value="" />
	<table border="0" cellpadding="3" cellspacing="2" class="no-style">
	  <tr><td><span class="text">Program:</span></td>
		    <td>${itemBankHtml}</td>
		</tr>
		<tr><td><span class="text">Description</span></td><td><input type="text" name="description" size="40" value="$bank->{description}" /></td></tr>
		<tr><td><span class="text">Owner</span></td><td><input type="text" name="owner" size="40" value="$bank->{owner}" /></td></tr>
		<tr><td><span class="text">Base URL</span></td><td><input type="text" name="hostBase" size="40" value="$bank->{hostBase}" /></td></tr>
	  	<tr><td><span class="text">Assign Standard:</span></td> <td>${standardHtml}</td> </tr>
  </table>
	<br /><br />
	<table border="1" cellpadding="2" cellspacing="2" >
	  <tr>
END_HERE

    foreach my $role ( sort { $a <=> $b }  keys %review_type )  {
      $psgi_out .= '<th align="left" width="190px">' . $review_type{$role} . "</th>\n";
    }

    $psgi_out .= '</tr><tr>';

    foreach my $role ( sort { $a <=> $b }  keys %review_type ) 
    {
        $psgi_out .= '<td valign="top">';

        foreach my $key ( sort { $users->{$a}{name} cmp $users->{$b}{name} }
            grep { $users->{$_}{reviewType} == $role } keys %$users )
        {

            my $checked =
              exists( $users->{$key}{itemBanks}{ $in{itemBankId} } )
              ? 'CHECKED'
              : '';

            $psgi_out .= <<END_HERE;
			   <div style="margin-top:2px;margin-bottom:2px;border-bottom:1px solid black;"><input type="checkbox" name="user_${key}" value="yes" ${checked} />&nbsp;&nbsp;$users->{$key}{name}</div>
END_HERE
        }

        $psgi_out .= '&nbsp;</td>';
    }

    $psgi_out .= '</tr>';

    $psgi_out .= <<END_HERE;
	</table>
	<br />
	<p><input type="button" value="Save" onClick="doSaveSubmit();" /></p>
	</form>
	</body>
</html>	
END_HERE

  return $psgi_out;
}
1;
