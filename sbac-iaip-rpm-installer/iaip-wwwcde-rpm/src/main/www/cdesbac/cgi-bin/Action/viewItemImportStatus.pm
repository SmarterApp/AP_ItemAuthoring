package Action::viewItemImportStatus;

use ItemConstants;
use Item;
use Data::Dumper;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $IIA_CREATE = 1;
  our $IIA_UPDATE = 2;
  our $IIA_ERROR = 3;
  our $IIA_ROLLED_BACK = 4;
  
  our $IIM_STARTED = 1;
  our $IIM_VALIDATED_PACKAGE = 2;
  our $IIM_VALIDATED_CONTENT = 3;
  our $IIM_COMPLETED = 4;
  our $IIM_FAILED_PACKAGE = 5;
  our $IIM_FAILED_CONTENT = 6;
  our $IIM_ROLLED_BACK = 7;
  
  our %monitor_status_label = ( 1 => 'Started',
                               2 => 'Validated Package',
  			     3 => 'Validated Content',
  			     4 => 'Completed',
  			     5 => 'Failed Package',
  			     6 => 'Failed Content',
  			     7 => 'Rolled Back');
  
  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $in{myAction} = '' unless exists $in{myAction};
  
  # first, process any actions from this page
  
  if($in{myAction} eq 'rollback') {
  
    # only include items in rollback if they have not since been modified
  
    $sql = <<SQL;
    SELECT iia.*, iim.iim_timestamp, i.i_dev_state FROM item_import_action AS iia, item_import_monitor AS iim, item AS i
      WHERE iim.iim_id=$in{importId} 
        AND iim.ua_id=iia.ua_id 
        AND iia.iia_type IN ($IIA_CREATE, $IIA_UPDATE)
        AND iia.i_id=i.i_id
        AND iim.iim_timestamp >= i.i_last_modified
SQL
  
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    while(my $row = $sth->fetchrow_hashref) {
  
      if($row->{iia_type} == $IIA_CREATE) {
  
        # we created the item in this import, so delete it 
  
        my $item = new Item($dbh, $row->{i_id});
        $item->remove();
        
        my $sth2;
  
        my @deleters = qw/item_fragment item_import_action/;
  
        foreach (@deleters) {
  
          $sql = sprintf('DELETE FROM ' . $_ . ' WHERE i_id=%d', $row->{i_id});
          $sth2 = $dbh->prepare($sql);
          $sth2->execute();
        }
  
      } elsif ($row->{iia_type} == $IIA_UPDATE ) {
  
        # we updated the item in this import, so set the content based on the state before
        $sql = <<SQL;
        SELECT * FROM item_status 
          WHERE i_id=$row->{i_id}
  	  AND is_timestamp < '$row->{iim_timestamp}'
  	  ORDER BY is_timestamp DESC LIMIT 1
SQL
  
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute();
  
        if(my $row2 = $sth2->fetchrow_hashref) {
  
  	my @old_item_fragments = ();
  	$sql = <<SQL;
  	SELECT itf.*, isf.isf_text 
  	  FROM item_fragment AS itf, item_status_fragment AS isf 
  	    WHERE isf.is_id=$row2->{is_id} 
  	      AND isf.if_id=itf.if_id
SQL
  	my $sth3 = $dbh->prepare($sql);
  	$sth3->execute();
  	while(my $row3 = $sth3->fetchrow_hashref) {
  
  	  # create a new fragment based on the old
  	  $sql = ('INSERT INTO item_fragment SET i_id=%d, ii_id=%d, if_type=%d, if_seq=%d, if_identifier=%s, if_text=%s, if_attribute_list=%s',
  	          $row3->{i_id},
  		  $row3->{ii_id},
  		  $row3->{if_type},
  		  $row3->{if_seq},
  		  $dbh->quote($row3->{if_identifier}),
  		  $dbh->quote($row3->{isf_text}),
  		  $dbh->quote($row3->{if_attribute_list}));
  
  	  my $sth3 = $dbh->prepare($sql);
  	  $sth3->execute();
           
  	  push @old_item_fragments, $row3->{if_id}; 
  	}
  
          # clear the existing fragments
          $sql = 'DELETE FROM item_fragment WHERE if_id IN (' . join (',', @old_item_fragments) . ')';
  	$sth3 = $dbh->prepare($sql);
  	$sth3->execute();
  
          # 'item_status' table has the last xml
  
          # update the QTI and TEI data
  
          $sql = sprintf('UPDATE item SET i_qti_xml_data=%s, i_tei_data=%s WHERE i_id=%d',
                       $dbh->quote($row2->{qti_xml} || ''),
  		     $dbh->quote($row2->{tei_xml} || ''),
  		     $row->{i_id});
          $sth3 = $dbh->prepare($sql);
          $sth3->execute();
  
          # finally, set a state change
          &setItemReviewState($dbh, $row->{i_id}, $row->{i_dev_state}, $row->{i_dev_state}, $user->{id});
  
        } else {
          # nothing we can do 
        }
  
      }
  
      # now update the status of the import action, if it has changed
  
      if($row->{iia_type} == $IIA_CREATE || $row->{iia_type} == $IIA_UPDATE) {
  
       $sql = <<SQL;
        UPDATE item_import_action 
        SET iia_type=${IIA_ROLLED_BACK}
        WHERE ua_id=$row->{ua_id}
          AND i_id=$row->{i_id}
SQL
     
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute();
      }
  
    } # end foreach item
  
    # finally, update the status of this item import operation
  
    $sql = <<SQL;
    UPDATE item_import_monitor 
      SET iim_status=${IIM_ROLLED_BACK}, iim_status_detail='Rolled Back' 
      WHERE iim_id=$in{importId}
SQL
    $sth = $dbh->prepare($sql);
    $sth->execute();
  
    $in{message} = 'Rolled back item import operation. See status for details.';
  
  } # end myAction eq 'rollback'
  
  # build the data structure for the html template
  
  our %importActionList = ();
  
  my $itemBankIdListStr = join (',', keys %$banks);
  
  $sql = <<SQL;
  SELECT iim.*, u.u_first_name, u.u_last_name 
    FROM item_import_monitor AS iim, user AS u 
    WHERE iim.u_id=u.u_id
SQL
  
  # only select item banks which the user can access
  $sql .= " AND ib_id IN (${itemBankIdListStr})";
  
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  while(my $row = $sth->fetchrow_hashref) {
  
    my $key = $row->{iim_id};
  
    my %data = ();
   
    $data{bankId} = $row->{ib_id};
    $data{bankName} = $banks->{$row->{ib_id}}{name};
    $data{userFirstName} = $row->{u_first_name};
    $data{userLastName} = $row->{u_last_name};
    $data{importTimestamp} = $row->{iim_timestamp};
    $data{status} = $monitor_status_label{$row->{iim_status}};
    $data{statusDetail} = $row->{iim_status_detail};
    $data{fileName} = $row->{iim_import_file_name};
    $data{fileTimestamp} = $row->{iim_import_file_modified};
    $data{itemCount} = 0;
  
    $sql = sprintf('SELECT COUNT(*) AS item_count FROM item_import_action WHERE ua_id=%d', $row->{ua_id});
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute();
    if(my $row2 = $sth2->fetchrow_hashref) {
      $data{itemCount} = $row2->{item_count};
    }
    $sth2->finish;
  
    $importActionList{$key} = \%data; 
  }

  return [ $q->psgi_header('text/html'), [ &print_welcome() ]];
  
}
# All done!

sub print_welcome {
  my $psgi_out = '';

    my $msg = (
        defined( $in{message} )
        ? '<div style="color:#0000ff;font-weight:bold">'
          . $in{message}
          . "</div>"
        : "" );

    my $documentReadyJs = '';

    if(scalar keys %importActionList) {
      
      $documentReadyJs .= "\$(\"#viewTable\").tablesorter();\n";
    }

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>CDE Item Import Monitor</title>
    <link rel="stylesheet" href="${orcaUrl}style/text.css" type="text/css" />
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="Javascript">

      \$(document).ready(function()
			  {
          ${documentReadyJs}
        }
      );

      function onItemBankChange() {
 
	document.viewForm.submit();
        
      }

      function doRollback(id, bankId) {
       
        if(confirm("Are you sure you want to rollback this import?")) {

	  document.rollbackForm.importId.value = id;
	  document.rollbackForm.bankId.value = bankId;
	  document.rollbackForm.submit();

	} else {

          // do nothing

	}
      }

      function viewImportDetail(id, bankId) {

        window.open('viewItemImportDetail.pl?importId=' + id + '&bankId=' + bankId, 'detailWin', 'width=600,height=400,left=100,top=100,menubar=no,toolbar=no');
      }
    </script>
  </head>
  <body>
    <div class="title">Item Import Monitor</div>
    ${msg} 
   <br />
   <form name="rollbackForm" action="viewItemImportStatus.pl" method="POST">
     
     <input type="hidden" name="myAction" value="rollback" />
     <input type="hidden" name="bankId" value="" />
     <input type="hidden" name="importId" value="" />
   </form>
   <form name="viewForm" action="viewItemImportStatus.pl" method="POST">
     
END_HERE

    if(scalar keys %importActionList) {

      $psgi_out .= <<END_HERE;
      <table id="viewTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2" align="left">
     <thead>
     <tr>
       <th width="10%">Time</th>
       <th width="12%">Program</th>
       <th width="8%">Status</th>
       <th width="10%">Detail</th>
       <th width="10%">File</th>
       <th width="12%">File Time</th>
       <th width="10%">User</th>
       <th width="8%">View</th>
       <th width="10%">Action</th>
     </tr>
     </thead>
     <tbody>
END_HERE

      foreach my $key (sort { $importActionList{$b}{importTimestamp} cmp $importActionList{$a}{importTimestamp} }
                     keys %importActionList) {

        my $data = $importActionList{$key};

        my $action = '&nbsp;';
	my $viewLink = '&nbsp;';

        if($data->{status} eq 'Completed' && $data->{itemCount}) {
          $action = <<END_HERE;
	  <input type="button" value="Rollback" style="font-size:small;" onClick="doRollback('${key}','$data->{bankId}');" />
END_HERE

          $viewLink = <<END_HERE;
	<input type="button" value="View" style="font-size:small;" 
	           onClick="viewImportDetail('${key}','$data->{bankId}');" />
END_HERE

        }



        $psgi_out .= <<END_HERE;
        <tr>
        <td>$data->{importTimestamp}</td>
        <td>$data->{bankName}</td>
        <td>$data->{status}</td>
        <td>$data->{statusDetail}</td>
	<td>$data->{fileName}</td>
        <td>$data->{fileTimestamp}</td>
	<td>$data->{userLastName}, $data->{userFirstName}</td>
	<td>${viewLink}</td>
	<td>${action}</td>
        </tr>
END_HERE
      }

      $psgi_out .= <<END_HERE;
    </tbody>
   </table>
END_HERE

    } else {

      $psgi_out .= '<p>No Item Import actions have been processed.</p>';
    }

    $psgi_out .= <<END_HERE;
   </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}
1;
