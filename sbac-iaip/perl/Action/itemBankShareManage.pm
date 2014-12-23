package Action::itemBankShareManage;

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
  $in{itemBankId} = (keys %$banks)[0] unless exists $in{itemBankId};

  if($in{myAction} && $in{myAction} eq 'save') {

    # clear the existing shares

    $sql = 'DELETE FROM item_bank_share WHERE ib_id=' . $in{itemBankId};
    $sth = $dbh->prepare($sql);
    $sth->execute();

    # load the current share list
    my @shareList = map { $_ =~ /(\d+)$/; $1; } grep { $_ =~ /^bank_share_/ } keys %in;

    foreach my $ib_key (@shareList) {
      $sql = 'INSERT INTO item_bank_share SET ib_id=' . $in{itemBankId} . ', ibs_ib_share_id=' . $ib_key; 
      $sth = $dbh->prepare($sql);
      $sth->execute();
    }

    $in{message} = 'Share list updated.'; 

  }
  
  # build the data structure for the html template
  
  our %actionList = ();
  
  our $itemBankIdListStr = join (',', keys %$banks);
  
  $sql = <<SQL;
  SELECT item_bank.*, organization.o_name, item_bank_share.ibs_id
    FROM item_bank 
    LEFT JOIN organization 
      ON item_bank.o_id=organization.o_id
    LEFT JOIN item_bank_share
      ON item_bank_share.ib_id=$in{itemBankId} AND item_bank_share.ibs_ib_share_id=item_bank.ib_id
    GROUP BY item_bank.ib_id
SQL
  
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  while(my $row = $sth->fetchrow_hashref) {

    # dont share with self
    next if $row->{ib_id} == $in{itemBankId};
  
    my $key = $row->{ib_id};
  
    my %data = ();
   
    $data{bankName} = $row->{ib_external_id};
    $data{orgName} = $row->{o_name};
    $data{bankShare} = $row->{ibs_id};
  
    $actionList{$key} = \%data; 
  }
  $sth->finish;
  
  return [ $q->psgi_header('text/html'), [ &print_welcome() ] ];
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
      &hashToSelect( 'itemBankId', \%itemBanks, $in{itemBankId}, 'doReload();', '', '', 'width:200px;' );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>CDE Manage Program Share</title>
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

      function doSaveSubmit() {
        document.form1.myAction.value = 'save';
	document.form1.submit();
      }

      function doReload() {
        document.form1.myAction.value = '';
	document.form1.submit();
      }

    </script>
  </head>
  <body>
    <div class="title">Program Share</div>
    ${msg} 
   <br />
   <form name="form1" action="itemBankShareManage.pl" method="POST">
     <input type="hidden" name="myAction" value="" />
     
   <table class="no-style" border="0" cellspacing="2" cellpadding="2">
     <tr>
       <td>Target Program:</td>
       <td>${bankDisplay}</td>
       <td><input type="button" value="Save" onClick="doSaveSubmit();" />
     </tr>
   </table>
   <table id="viewTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2">
     <thead>
     <tr>
       <th width="60">Share ?</th>
       <th width="90">Organization</th>
       <th width="140">Program</th>
     </tr>
     </thead>
     <tbody>
END_HERE

    foreach my $key (sort { $actionList{$a}{orgName} cmp $actionList{$b}{orgName}
                         || $actionList{$a}{bankName} cmp $actionList{$b}{bankName} }
                     keys %actionList) {

      my $data = $actionList{$key};
      
      my $selected = $data->{bankShare} ? 'CHECKED' : '';

      $psgi_out .= <<END_HERE;
      <tr>
        <td><input type="checkbox" name="bank_share_${key}" value="1" ${selected} />  
        <td>$data->{orgName}</td>
        <td>$data->{bankName}</td>
      </tr>
END_HERE
    }

    $psgi_out .= <<END_HERE;
    </tbody>
   </table>
   </form>
  </body>
</html>         
END_HERE

  return $psgi_out;
}
1;
