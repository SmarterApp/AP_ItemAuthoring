package Action::viewItemAuditReport;

use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  # build the data structure for the html template
  
  our %actionList = ();
  
  our $itemBankIdListStr = join (',', keys %$banks);
  
  our $filterCriteria = '';
  
  if(exists($in{itemBankId}) && $in{itemBankId} ne '') {
    $filterCriteria .= ' AND i.ib_id=' . $in{itemBankId};
  }
  
  if(exists($in{publicationStatus}) && $in{publicationStatus} ne '') {
    $filterCriteria .= ' AND i.i_publication_status=' . $in{publicationStatus};
  }
  
  if(exists($in{process}) && $in{process} ne '') {
    $filterCriteria .= ' AND uai.uai_process LIKE \'%' . $in{process} . '%\'';
  }
  
  # adjust the criteria for the deleted items to account for different prefix
  
  our $filterCriteriaDeleted = $filterCriteria;
  $filterCriteriaDeleted =~ s/AND i\./AND di\./g;
  
  $sql = <<SQL;
  (SELECT uai.*, u.u_first_name, u.u_last_name, u.u_username, i.i_external_id, i.ib_id, i.i_dev_state, 
         i.i_publication_status
    FROM user_action_item AS uai, user AS u, item AS i 
    WHERE uai.u_id=u.u_id
      AND uai.i_id=i.i_id
      AND i.ib_id IN (${itemBankIdListStr}) ${filterCriteria} ORDER BY uai.uai_timestamp DESC LIMIT 100)
  UNION
  (SELECT uai.*, u.u_first_name, u.u_last_name, u.u_username, di.i_external_id, di.ib_id, di.i_dev_state, 
         di.i_publication_status
    FROM user_action_item AS uai, user AS u, deleted_item AS di
    WHERE uai.u_id=u.u_id
      AND uai.i_id=di.i_id
      AND di.ib_id IN (${itemBankIdListStr}) ${filterCriteriaDeleted} ORDER BY uai.uai_timestamp DESC LIMIT 100)
SQL
  
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  while(my $row = $sth->fetchrow_hashref) {
  
    my $key = $row->{uai_id};
  
    my %data = ();
   
    $data{bankId} = $row->{ib_id};
    $data{bankName} = $banks->{$row->{ib_id}}{name};
    $data{itemName} = $row->{i_external_id};
    $data{userFirstName} = $row->{u_first_name};
    $data{userLastName} = $row->{u_last_name};
    $data{userName} = $row->{u_username};
    $data{devState} = $dev_states{$row->{i_dev_state}};
    $data{pubStatus} = $publication_status{$row->{i_publication_status}};
    $data{actionTimestamp} = $row->{uai_timestamp};
    $data{process} = $row->{uai_process};
    $data{detail} = $row->{uai_detail};
  
    $sql = <<SQL;
    SELECT is_id, ib_id FROM item_status 
      WHERE i_id=$row->{i_id}
        AND is_last_dev_state=$row->{i_dev_state}
        AND is_timestamp >= '$row->{uai_timestamp}'
        ORDER BY is_timestamp ASC LIMIT 1
SQL
  
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute();
  
    if(my $row2 = $sth2->fetchrow_hashref) {
      $data{viewLink} = "item-pdf/lib$row2->{ib_id}/$row->{i_id}/$row2->{is_id}.pdf";
    } else {
      $data{viewLink} ="cgi-bin/itemSingleView.pl?itemId=$row->{i_id}";
    }
    $sth2->finish;
  
    $actionList{$key} = \%data; 
  }
  $sth->finish;
  
  # check to see if user wants a CSV export
  
  if(exists($in{doExport}) && $in{doExport} eq 'csv') {
  
    my $csv_out = <<CSV;
Time,Program,Item,Dev State,Pub Status,Process,Detail,User Last Name,User First Name,Login
CSV
  
    foreach my $key (sort { $actionList{$b}{actionTimestamp} cmp $actionList{$a}{actionTimestamp} }
                       keys %actionList) {
  
      my $data = $actionList{$key};
  
      $csv_out .= join (',', map { '"' . $data->{$_} . '"' } 
                       qw/actionTimestamp bankName itemName devState pubStatus process detail
  		       userLastName userFirstName userName/ );
      $csv_out .= "\n"; 
    }
    
    return [ $q->psgi_header( -type => 'text/csv',
                              -attachment => 'item_audit_log.csv' ),
             [ $csv_out ] ];
  
  } else {
  
    # ok, just show the regular html report
  
    return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
  }
  
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

    my %itemBanks = map { $_ => $banks->{$_}{name} } keys %$banks;
    my $bankDisplay =
      &hashToSelect( 'itemBankId', \%itemBanks, $in{itemBankId}, '', 'null:All', '', 'width:170px;' );

    my $publicationStatusDisplay =
      &hashToSelect( 'publicationStatus', \%publication_status,
        $in{publicationStatus}, '', 'null:All', '', '' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>CDE Item Audit Log</title>
    <link rel="stylesheet" href="${orcaUrl}style/text.css" type="text/css" />
    <link rel="stylesheet" href="${orcaUrl}style/tablesorter/style.css" type="text/css" />
    <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="${commonUrl}js/jquery.tablesorter.min.js"></script>
    <script language="Javascript">

      \$(document).ready(function()
			  {
				  \$("#viewTable").tablesorter();
        }
      );

      function exportToCSV () {
      
        document.viewForm.doExport.value = 'csv';
        document.viewForm.submit(); 
      }

      function filterResults () {
        document.viewForm.doExport.value = '';
        document.viewForm.submit(); 
      }

    </script>
  </head>
  <body>
    <div class="title">Item Audit Log</div>
    ${msg} 
   <br />
   <form name="viewForm" action="viewItemAuditReport.pl" method="POST">
     
     <input type="hidden" name="doExport" value="" />
   <table class="no-style" border="0" cellspacing="2" cellpadding="2">
     <tr>
       <td>Program:</td>
       <td>${bankDisplay}</td>
       <td>&nbsp;</td>
       <td>Process:</td>
       <td><input type="text" name="process" value="$in{process}" size="15" /></td>
       <td>&nbsp;</td>
       <td>Pub Status:</td>
       <td>${publicationStatusDisplay}</td>
       <td>&nbsp;</td>
       <td><input type="button" name="filter" value="Filter" onClick="filterResults();" />
       <td style="width:30px;">&nbsp;</td>
       <td><input type="button" name="filter" value="Export to CSV" onClick="exportToCSV();" />
     </tr>
   </table>
   </form>
   <table id="viewTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2">
     <thead>
     <tr>
       <th width="10%">Time</th>
       <th width="10%">Program</th>
       <th width="10%">Item</th>
       <th width="10%">Dev State</th>
       <th width="10%">Pub Status</th>
       <th width="10%">Process</th>
       <th width="10%">Detail</th>
       <th width="10%">User</th>
       <th width="10%">Login</th>
       <th width="10%">View</th>
     </tr>
     </thead>
     <tbody>
END_HERE

    foreach my $key (sort { $actionList{$b}{actionTimestamp} cmp $actionList{$a}{actionTimestamp} }
                     keys %actionList) {

      my $data = $actionList{$key};

      $data->{detail} = '&nbsp;' if $data->{detail} eq '';

      my $view = 'Not Available';
     
      # provide item view if it isn't deleted
      if($data->{detail} !~ /Delete/) {

        # see whether we have a link to a PDF or the item viewer
        if($data->{viewLink} =~ /cgi-bin/) {

          $view ='<a href="' . $orcaUrl . $data->{viewLink} . '" target="_blank">View</a>'

        } else {

	  # make sure the link is present
	  if(-e $orcaPath . $data->{viewLink}) {
            $view ='<a href="' . $orcaUrl . $data->{viewLink} . '" target="_blank">View</a>'
	  } 
        } 
      }

      $psgi_out .= <<END_HERE;
      <tr>
        <td>$data->{actionTimestamp}</td>
        <td>$data->{bankName}</td>
        <td>$data->{itemName}</td>
        <td>$data->{devState}</td>
        <td>$data->{pubStatus}</td>
        <td>$data->{process}</td>
        <td>$data->{detail}</td>
	<td>$data->{userLastName}, $data->{userFirstName}</td>
	<td>$data->{userName}</td>
	<td>${view}</td>
      </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    </tbody>
   </table>
  </body>
</html>         
END_HERE

  return $psgi_out;
}
1;
