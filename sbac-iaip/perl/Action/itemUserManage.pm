package Action::itemUserManage;

use Crypt::GeneratePassword qw(word chars);
use Digest::SHA;
use ItemConstants;
use File::Glob ':glob';
use Session;
use Auth;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/itemUserManage.pl";
  
  our $sth;
  our $sql;
  
  # Authorize user (must be user type UT_ITEM_EDITOR and be an admin)
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and ($user->{adminType} == $UA_SUPER || $user->{adminType} == $UA_ORG) )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth() ]];
  }
  
  our $orgs = &getOrganizations($dbh);
  our %org_label = map { $_ => $orgs->{$_}{name_escaped} } keys %$orgs;
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq 'addUser' ) {
  
      $sql =
        "SELECT u_id FROM user WHERE u_username=" . $dbh->quote( $in{userName} );
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      if ( $sth->fetchrow_hashref ) {
          $in{errorMsg} = "User '$in{userName}' already exists.";
      }
      else {
  
        my $orgId = ($user->{adminType} == $UA_SUPER) ? $in{organizationId} : $user->{organizationId};
  
        $sql = sprintf('INSERT INTO user SET u_username=%s, u_password=%s, u_type=%d, u_review_type=%d, u_admin_type=%d, o_id=%d, u_active=1, u_permissions=1, u_first_name=%s, u_last_name=%s, u_email=%s, u_writer_code=%s',
                       $dbh->quote( $in{userName} ),
                       $dbh->quote( "INVALID PASSWORD" ),
                       $UT_ITEM_EDITOR,
  		     $in{reviewType},
  		     $in{adminType},
  		     $orgId,
                       $dbh->quote($in{firstName}),
                       $dbh->quote($in{lastName}),
                       $dbh->quote($in{eMail}),
                       $dbh->quote($in{writerCode}));
          $sth = $dbh->prepare($sql);
          $sth->execute();
  
          my $reviewType = $review_type{ int( $in{"reviewType"} ) };
          my $adminMessage = '';
  
  	if($in{adminType}) {
  
  	  $adminMessage = '(You have been assigned ' . $admin_type{$in{adminType}} . ' privileges)'; 
  	}
  
          my $messageData = <<END_HERE;
  Hello, $in{firstName}!
  
    Your SBAC IAIP account has been created. A follow-up email will provide a link to set your password. Please follow the directions in the email and login at: https://${webHost}${orcaUrl}
  
    Username: $in{userName} 
  
    You have been given a ${reviewType} account.
    ${adminMessage}
  
    You will receive other email shortly containing a link change your password.
  
    If you have any questions regarding your account, 
    please contact at SBAC7PacMetTeam\@pacificmetrics.com.
  
  Thanks and Have Fun!
  
    Pacific Metrics Corporation
  
END_HERE
  
          # Send e-mail notification
          my $message = MIME::Lite->new(
              To      => $in{eMail},
              From    => '"SBAC IAIP" <SBAC7PacMetTeam@pacificmetrics.com>',
              Subject => 'SBAC IAIP Login',
              Data    => $messageData
          );
  
          $message->send( 'smtp', 'localhost' );
  
          $in{msg} = "Added New User '$in{userName}'.";
  
          Auth::passwdResetRequest($dbh,$in{userName},"https://${webHost}${orcaUrl}");
      }
  
      $in{myAction} = '';
  }
  elsif ( $in{myAction} eq 'remindUser' ) {
      my $msg = Auth::passwdResetRequest($dbh,$in{userName},"https://${webHost}${orcaUrl}");
      if( $msg eq '' ) {
          $in{msg} = 'Password reminder sent.';
      }
      else {
          $in{errorMsg} = $msg;
      }
  
      $in{myAction} = '';
  }
  elsif ( $in{myAction} eq 'saveUser' ) {
  
    my $isDisabled = exists( $in{isDisabled} ) ? 1 : 0;
  
    $sql = sprintf('UPDATE user SET u_first_name=%s, u_last_name=%s, u_email=%s, u_writer_code=%s, u_review_type=%d, u_admin_type=%d, u_deleted=%d WHERE u_id=%d',
                    $dbh->quote( $in{firstName} ),
                    $dbh->quote( $in{lastName} ),
                    $dbh->quote( $in{eMail} ),
                    $dbh->quote( $in{writerCode} ),
  		 $in{reviewType},
  		 $in{adminType},
  		 $isDisabled,
  		 $in{userId});
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
      $in{msg}      = "Updated User '$in{userName}'.";
      $in{myAction} = '';
  }
  elsif ( $in{myAction} eq 'removeUser' ) {
  
      $in{myAction} = '';
  }
  
  my %u = ();
  
  $sql =
  "SELECT u.* FROM user AS u WHERE u.u_type=${UT_ITEM_EDITOR}";
  
  if($in{myAction} eq 'editUser') {
  
    $sql .= " AND u.u_id=$in{userId}"; 
  }
  
  if($user->{adminType} == $UA_ORG) {
    $sql .= ' AND u.o_id=' . $user->{organizationId};
  }
  
  $sth = $dbh->prepare($sql);
  $sth->execute();
  while ( my $row = $sth->fetchrow_hashref ) {
      my $id = $row->{u_id};
      $u{$id}            = {};
      $u{$id}{lastName}  = $row->{u_last_name};
      $u{$id}{firstName} = $row->{u_first_name};
      $u{$id}{writerCode} = $row->{u_writer_code};
      $u{$id}{eMail}     = $row->{u_email};
      $u{$id}{name}      = $row->{u_username};
      $u{$id}{reviewType} = $row->{u_review_type};
      $u{$id}{adminType} = $row->{u_admin_type};
      $u{$id}{organizationId} = $row->{o_id};
      $u{$id}{isDisabled} = $row->{u_deleted};
  
  }
  $sth->finish;
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome(\%u) ]];
  }
  
  if ( $in{myAction} eq 'editUser') {
    return [ $q->psgi_header('text/html'), [ &print_edit_user( $u{$in{userId}} ) ]]; 
  }
}

### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    my $users = shift;

    my $messageHtml = (
        exists $in{msg}
        ? '<div style="color:blue;font-weight:bold;">' . $in{msg} . '</div>'
        : '' );
    my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:red;font-weight:bold;">' . $in{errorMsg} . '</div>'
        : '' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>   
<html>
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="JavaScript">

      \$(document).ready(function()
	  {
         	  \$("#viewTable").tablesorter();
        }
      );

		  var status_obj = {};
		  function editUserSubmit(id) {
			  document.form1.userId.value = id;
			  document.form1.myAction.value = 'editUser';
				document.form1.submit();
			}

		  function remindUserSubmit(name) {
			  document.form1.userName.value = name;
			  document.form1.myAction.value = 'remindUser';
				document.form1.submit();
			}

			function addUserSubmit(f) {
				if( f.userName.value.match(/^\\s*\$/) ) {    	    
				    alert('Please Enter Required Field Username.');    	    
				    f.userName.focus();    	    
				    return false;	
				}
				if(! f.userName.value.match(/^[\\w]{6,30}\$/) ) {    	    
				    alert('Username must be at 6 to 30 characters long.\\nAlphanumeric characters only.');
				    f.userName.focus();    	    
				    return false;	
				}
				if( f.firstName.value.match(/^\\s*\$/) ) {    	    
				    alert('Please Enter Required Field First Name.');    	    
				    f.firstName.focus();    	    
				    return false;	
				}
				if( f.eMail.value.match(/^\\s*\$/) ) {    	    
				    alert('Please Enter Required Field Email.');    	    
				    f.eMail.focus();    	    
				    return false;	
				}
				if( f.reviewType.value == '' ) {    	    
				    alert('Please Enter Required Review Type.');    	    
				    f.reviewType.focus();    	    
				    return false;	
				}
				

				f.submit();
			}

  	  </script>
	</head>
	<body>
	<div class="title">User Management</div>
	${messageHtml}
	${errorHtml}
	<form name="form1" action="${thisUrl}" method="POST">
	  
	  <input type="hidden" name="myAction" value="editUser" />
		<input type="hidden" name="userId" value="" />
                <input type="hidden" name="userName" value="" />
        <table id="viewTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2">
	  <thead>
	  <tr>
		<th width="10%">Last Name</th>
		<th width="10%">First Name</th>
		<th width="11%">Org</th>
		<th width="10%">Login</th>
		<th>E-mail</th>
		<th>Review Type</th>
		<th>Admin Type</th>
		<th width="7%">Inactivated?</th>
		<th width="5%">Edit</th>
		<th width="5%">PW Reset</th>
		</tr>	
              </thead>
	     <tbody>
END_HERE

    foreach my $user (
        sort {
            $users->{$a}{lastName} cmp $users->{$b}{lastName}
              || $users->{$a}{firstName} cmp $users->{$b}{firstName}
        } keys %{$users}
      )
    {
        my $typeHtml = $review_type{$users->{$user}{reviewType}};
        my $adminHtml = $admin_type{$users->{$user}{adminType}};
        my $disabledChecked = $users->{$user}{isDisabled} ? 'Yes' : '';
        $psgi_out .= <<END_HERE;
    <tr>
		  <td>$users->{$user}{lastName}</td>
			<td>$users->{$user}{firstName}</td>
			<td>$orgs->{$users->{$user}{organizationId}}{name}</td>
			<td>$users->{$user}{name}</td>
			<td>$users->{$user}{eMail}</td>
			<td>${typeHtml}</td>
			<td>${adminHtml}</td>
			<td>${disabledChecked}</td>
			<td><input type="button" value="Edit" onClick="editUserSubmit('${user}');" /></td>
			<td><input type="button" value="Send" onClick="remindUserSubmit('$users->{$user}{name}');" /></td>
    </tr>
END_HERE
    }

    my $reviewTypeHtml = &hashToSelect( 'reviewType', \%review_type_without_none, '', '',
					'null', '', 'width:175px;' );
    my $adminTypeHtml =
        &hashToSelect( "adminType", \%admin_type, '',
                       '',  '', '', 'width:160px;' );

    $psgi_out .= <<END_HERE;
    </tbody>
    </table>
		<br /><br />
		</form>
		<form name="form2" action="${thisUrl}" method="POST">
	  
	  <input type="hidden" name="myAction" value="addUser" />
    <div class="title">Add New User</div>
		<table border="0" cellpadding="3" cellspacing="3" class="no-style">
END_HERE

    if($user->{adminType} == $UA_SUPER) {

      my $orgHtml = &hashToSelect( 'organizationId', \%org_label, '', '', '', '', '');

      $psgi_out .= <<END_HERE;
      <tr>
        <td><span class="text">Organization:</span></td>
	<td>${orgHtml}</td>
      </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
		  <tr>
			  <td><span class="text">Username:</span></td><td><input type="text" name="userName" size="25" /> <font color="red" size="1">*</font></td>
			</tr>
		  <tr>
			  <td><span class="text">First Name:</span></td><td><input type="text" name="firstName" size="25" /> <font color="red" size="1">*</font></td>
			</tr>
		  <tr>
			  <td><span class="text">Last Name:</span></td><td><input type="text" name="lastName" size="25" /></td>
			</tr>
		  <tr>
			  <td><span class="text">E-Mail:</span></td><td><input type="text" name="eMail" size="25" /> <font color="red" size="1">*</font></td>
			</tr>
		  <tr>
			  <td><span class="text">Writer Code:</span></td><td><input type="text" name="writerCode" size="25" /></td>
			</tr>
		  <tr>
			  <td><span class="text">Review Type:</span></td><td>${reviewTypeHtml}<font color="red" size="1">  *</font></td>
			</tr>
		  <tr>
			  <td><span class="text">Admin Type:</span></td><td>${adminTypeHtml}</td>
			</tr>
		  <tr>
			  <td colspan="2" align="center"><font color="red" size="1">* Required field</font></td>
			</tr>
      <tr>
			  <td colspan="2"><input type="button" value="Add New User" onClick="addUserSubmit(this.form);" /></td>
			</tr>
			</table>
		</form>	
	</body>
</html>	
END_HERE

  return $psgi_out;
}

sub print_edit_user {

    my $user  = shift;

    my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );

    my $reviewTypeHtml =
        &hashToSelect( "reviewType", \%review_type_without_none,
            $user->{reviewType}, '',  'null', '', 'width:160px;' );

    my $adminTypeHtml =
        &hashToSelect( "adminType", \%admin_type,
            $user->{adminType}, '',  '', '', 'width:160px;' );

    my $disabledChecked = $user->{isDisabled} ? 'CHECKED' : '';

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
		<script language="JavaScript">
		  
			function doSaveSubmit() {
			  document.editForm.myAction.value = 'saveUser';
				document.editForm.submit();
			}

			function doBackSubmit() {
			  document.editForm.myAction.value = '';
				document.editForm.submit();
			}

		</script>
	</head>
	<body>
	<div class="title">Edit User: '$user->{name}'</div>
	${errorHtml}
	<form name="editForm" action="${thisUrl}" method="POST">
	  
	  <input type="hidden" name="userId" value="$in{userId}" />
	  <input type="hidden" name="userName" value="$user->{name}" />
	  <input type="hidden" name="myAction" value="saveUser" />
	<table border="0" cellpadding="3" cellspacing="2" class="no-style">
	  <tr>
	    <td><span class="text">First name:</span></td>
	    <td><input type="text" name="firstName" size="40" value="$user->{firstName}" /></td>
	  </tr>
	  <tr>
	    <td><span class="text">Last name:</span></td>
	    <td><input type="text" name="lastName" size="40" value="$user->{lastName}" /></td>
	  </tr>
	<tr>
	  <td><span class="text">E-mail:</span></td>
	  <td><input type="text" name="eMail" size="40" value="$user->{eMail}" /></td>
        </tr>
	<tr>
	  <td><span class="text">Writer Code:</span></td>
	  <td><input type="text" name="writerCode" size="40" value="$user->{writerCode}" /></td>
        </tr>
	<tr>
	  <td><span class="text">Review Type:</span></td>
	  <td>${reviewTypeHtml}</td>
        </tr>
	<tr>
	  <td><span class="text">Admin Type:</span></td>
	  <td>${adminTypeHtml}</td>
        </tr>
	<tr>
	  <td><span class="text">Inactivate? :</td>
    	  <td><input type="checkbox" name="isDisabled" value="yes" ${disabledChecked} /></td>
        </tr>
        </table>
	<br />
	<p><input type="button" value="Save" onClick="doSaveSubmit();" /></p>
	<p><input type="button" value="Back" onClick="doBackSubmit();" /></p>
	</form>
	</body>
</html>	
END_HERE
}
1;