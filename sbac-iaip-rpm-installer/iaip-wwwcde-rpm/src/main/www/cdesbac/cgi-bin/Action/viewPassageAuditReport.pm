package Action::viewPassageAuditReport;

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
    $filterCriteria .= ' AND p.ib_id=' . $in{itemBankId};
  }
  
  if(exists($in{publicationStatus}) && $in{publicationStatus} ne '') {
    $filterCriteria .= ' AND p.p_publication_status=' . $in{publicationStatus};
  }
  
  if(exists($in{process}) && $in{process} ne '') {
    $filterCriteria .= ' AND uap.uap_process LIKE \'%' . $in{process} . '%\'';
  }
  
  # adjust the criteria for the deleted items to account for different prefix
  
  our $filterCriteriaDeleted = $filterCriteria;
  $filterCriteriaDeleted =~ s/AND p\./AND dp\./g;
  
  $sql = <<SQL;
  (SELECT uap.*, u.u_first_name, u.u_last_name, u.u_username, p.p_name, p.ib_id, p.p_dev_state, 
         p.p_publication_status
    FROM user_action_passage AS uap, user AS u, passage AS p 
    WHERE uap.u_id=u.u_id
      AND uap.p_id=p.p_id
      AND p.ib_id IN (${itemBankIdListStr}) ${filterCriteria} ORDER BY uap.uap_timestamp DESC LIMIT 100)
  UNION
  (SELECT uap.*, u.u_first_name, u.u_last_name, u.u_username, dp.p_name, dp.ib_id, dp.p_dev_state, 
         dp.p_publication_status
    FROM user_action_passage AS uap, user AS u, deleted_passage AS dp
    WHERE uap.u_id=u.u_id
      AND uap.p_id=dp.p_id
      AND dp.ib_id IN (${itemBankIdListStr}) ${filterCriteriaDeleted} ORDER BY uap.uap_timestamp DESC LIMIT 100)
SQL
  
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  while(my $row = $sth->fetchrow_hashref) {
  
    my $key = $row->{uap_id};
  
    my %data = ();
   
    $data{bankId} = $row->{ib_id};
    $data{bankName} = $banks->{$row->{ib_id}}{name};
    $data{passageName} = $row->{p_name};
    $data{userFirstName} = $row->{u_first_name};
    $data{userLastName} = $row->{u_last_name};
    $data{userName} = $row->{u_username};
    $data{devState} = $dev_states{$row->{p_dev_state}};
    $data{pubStatus} = $publication_status{$row->{p_publication_status}};
    $data{actionTimestamp} = $row->{uap_timestamp};
    $data{process} = $row->{uap_process};
    $data{detail} = $row->{uap_detail};
  
    $sql = <<SQL;
    SELECT ps_id, ib_id FROM passage_status 
      WHERE p_id=$row->{p_id}
        AND ps_last_dev_state=$row->{p_dev_state}
        AND ps_timestamp >= '$row->{uap_timestamp}'
        ORDER BY ps_timestamp ASC LIMIT 1
SQL
  
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute();
  
    if(my $row2 = $sth2->fetchrow_hashref) {
      $data{viewLink} = "passage-pdf/lib$row2->{ib_id}/$row->{p_id}/$row2->{ps_id}.pdf";
    } else {
      $data{viewLink} ="cgi-bin/passageView.pl?passageId=$row->{p_id}";
    }
    $sth2->finish;
  
    $actionList{$key} = \%data; 
  }
  $sth->finish;
  
  # check to see if user wants a CSV export
  
  if(exists($in{doExport}) && $in{doExport} eq 'csv') {
  
    my $csv_out = <<CSV;
Time,Program,Passage,Dev State,Pub Status,Process,Detail,User Last Name,User First Name,Login
CSV
  
    foreach my $key (sort { $actionList{$b}{actionTimestamp} cmp $actionList{$a}{actionTimestamp} }
                       keys %actionList) {
  
      my $data = $actionList{$key};
  
      $csv_out .= join (',', map { '"' . $data->{$_} . '"' } 
                       qw/actionTimestamp bankName passageName devState pubStatus process detail
  		       userLastName userFirstName userName/ );
      $csv_out .= "\n"; 
    }

    return [ $q->psgi_header( -type => 'text/csv',
                              -attachment => 'passage_audit_log.csv' ),
             [ $csv_out ] ];
  
  } else {
  
    # ok, just show the regular html report
    return [ $q->psgi_header('text/html'), [ &print_welcome() ]];  
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
    <title>CDE Passage Audit Log</title>
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
    <div class="title">Passage Audit Log</div>
    ${msg} 
   <br />
   <form name="viewForm" action="viewPassageAuditReport.pl" method="POST">
     
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
       <th width="10%">Passage</th>
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
        <td>$data->{passageName}</td>
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
