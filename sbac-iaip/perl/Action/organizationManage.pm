package Action::organizationManage;

use ItemConstants;
use File::Copy;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;

  our $thisUrl = "${orcaUrl}cgi-bin/organizationManage.pl";
  
  # Authorize user (must be user type UT_ITEM_EDITOR and be an admin)
  unless (exists( $user->{type} )
      and int( $user->{type} ) == $UT_ITEM_EDITOR
      and $user->{reviewType} )
  {
    return [ $q->psgi_header('text/html'), [ &print_no_auth ] ];
  }
  
  our $orgs = &getOrganizations($dbh);
  
  $in{organizationId} = 0 unless exists $in{organizationId};
  
  $in{myAction} = '' unless exists $in{myAction};
  
  if ( $in{myAction} eq '' ) {
    return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
  }
  
  if ( $in{myAction} eq 'addOrganization' ) {
  
      # make sure the name is unique
      
      my $sql = sprintf('SELECT * FROM organization WHERE o_name=%s', $dbh->quote($in{orgName}));
      my $sth = $dbh->prepare($sql);
      $sth->execute();
      if ( $sth->fetchrow_hashref ) {
        $in{errorMsg} = "Organization '$in{orgName}' already exists.";
	return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
      }
  
      # Create the 'organization' record
  
      $sql = sprintf('INSERT INTO organization SET o_name=%s, o_description=%s',
                     $dbh->quote($in{orgName}),
  		   $dbh->quote($in{orgDescription}));
      $sth = $dbh->prepare($sql);
      $sth->execute();
  
      # refresh the bank list
      $orgs = &getOrganizations($dbh);
  
      $in{errorMsg} = "Organization '$in{orgName}' has been added.";
  
      return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
  }
  elsif ( $in{myAction} eq 'editOrganization' ) {
    return [ $q->psgi_header('text/html'), [ &print_edit_org() ] ];
  }
  elsif ( $in{myAction} eq 'save' ) {
  
      # Put all of these statements in a transaction
  
      $dbh->{RaiseError} = 1;
      $dbh->{AutoCommit} = 0;
  
      {
          my $sql = sprintf( 'UPDATE organization SET o_name=%s, o_description=%s WHERE o_id=%d',
              $dbh->quote( $in{orgName} ),
              $dbh->quote( $in{orgDescription} ),
              $in{organizationId}
          );
          my $sth = $dbh->prepare($sql);
          $sth->execute();
  
      };
  
      if ($@) {
          $dbh->rollback();
          $in{errorMsg} = "Unable to update Organization '$in{orgName}'.";
      }
      else {
          $dbh->commit();
          $in{errorMsg} = "Updated Organization '$in{orgName}'.";
      }
      $dbh->{AutoCommit} = 1;
  
      # reload the orgs list
      $orgs = &getOrganizations($dbh);
  
      return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
  }
}
### ALL DONE! ###

sub print_welcome {
  my $psgi_out = '';

    # Let the user select an organization to edit, or add an organization 

    my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE HTML>
<html>
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    <script type="text/javascript" src="/common/js/encoder.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="Javascript">

      \$(document).ready(function() {

	  \$("#viewTable").tablesorter();

        }
      );

      function editOrganizationSubmit(id) {

        document.editForm.organizationId.value = id;
	document.editForm.submit();
      }

      function addOrganizationSubmit() {

	if( document.addForm.orgName.value.match(/^\\s*\$/) ) {
    	    alert('Please Enter a Organization Name to Add.');
    	    document.addForm.orgName.focus();
    	    return false;
	}

	document.addForm.submit();
      }

	</script>
	</head>
	<body>
	<div class="title">Organization Management</div>
	${errorHtml}
	<form name="editForm" action="${thisUrl}" method="POST">
	  
	  <input type="hidden" name="myAction" value="editOrganization" />
	  <input type="hidden" name="organizationId" value="" />
        </form>
   <table id="viewTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2">
     <thead>
     <tr>
       <th width="120">Name</th>
       <th width="300">Description</th>
       <th width="60">Edit</th>
     </tr>
     </thead>
     <tbody>
END_HERE

    foreach my $key (sort { $orgs->{$a}{name} cmp $orgs->{$b}{name} }
                     keys %$orgs) {

      my $data = $orgs->{$key};

      $psgi_out .= <<END_HERE;
      <tr>
        <td>$data->{name_escaped}</td>
        <td>$data->{description_escaped}</td>
	<td><input type="button" name="edit" value="Edit" onClick="editOrganizationSubmit('$key');" /></td>
      </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    </tbody>
   </table>
   <br />
   <form name="addForm" action="${thisUrl}" method="POST">
     
     <input type="hidden" name="myAction" value="addOrganization" />
   <table border="0" cellpadding="3" cellspacing="3" class="no-style">
     <tr>
       <td colspan="2"><span class="text">Add Organization</span></td>
     </tr>
     <tr>
       <td>Name:</td>
       <td><input type="text" size="20" name="orgName" maxlength="40" /></td>
     </tr>
     <tr>
       <td>Description:</td>
       <td><input type="text" size="40" name="orgDescription" maxlength="200" /></td>
     </tr>
     <tr>
       <td colspan="2">
         <input class="action_button" type="button" value="Add" onClick="addOrganizationSubmit();" />
       </td>
     </tr>	
   </table>
  </form>
 </body>
</html>	
END_HERE

  return $psgi_out;
}

sub print_edit_org {

    my $errorHtml = (
        exists $in{errorMsg}
        ? '<div style="color:blue;">' . $in{errorMsg} . '</div>'
        : '' );

    my $org  = $orgs->{ $in{organizationId} };

    return <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
<script type="text/javascript" src="/common/js/encoder.js"></script>
		<script language="JavaScript">
		  
			function doSaveSubmit() {
				if( document.editForm.orgName.value.match(/^\\s*\$/) ) {
    	    			    alert('Please Enter a Organization Name to Save.');
    	    			    document.editForm.orgName.focus();
    	    			    return false;
				}

			  	document.editForm.myAction.value = 'save';
				document.editForm.submit();
			}

			function doBackSubmit() {
			  document.editForm.myAction.value = '';
				document.editForm.submit();
			}

		</script>
	</head>
	<body>
	<div class="title">Edit Organization: '$org->{name}'</div>
	${errorHtml}
	<form name="editForm" action="${thisUrl}" method="POST">
	  
	  <input type="hidden" name="organizationId" value="$in{organizationId}" />
	  <input type="hidden" name="myAction" value="" />
	<table border="0" cellpadding="3" cellspacing="2" class="no-style">
	  <tr>
	    <td><span class="text">Organization:</span></td>
	    <td><input type="text" name="orgName" size="40" value="$org->{name_escaped}" /></td>
	  </tr>
	<tr>
	  <td><span class="text">Description:</span></td>
	  <td><input type="text" name="orgDescription" size="40" value="$org->{description_escaped}" /></td>
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
