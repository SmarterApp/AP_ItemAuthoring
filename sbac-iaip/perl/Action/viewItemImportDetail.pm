package Action::viewItemImportDetail;

use ItemConstants;
use Data::Dumper;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our %item_status_label = ( 1 => 'Created',
                            2 => 'Updated',
  			  3 => 'Error',
  			  4 => 'Rolled Back'
  		        );
  
  our $sth;
  our $sql;
  
  # build the data structure for the html template
  
  our %importActionList = ();
  
  $sql = <<SQL;
  SELECT iia.*, i.i_external_id 
    FROM item_import_action AS iia, item_import_monitor AS iim , item AS i
    WHERE iim.iim_id=$in{importId}
      AND iim.ua_id=iia.ua_id
      AND iia.i_id=i.i_id
SQL
  
  $sth = $dbh->prepare($sql);
  $sth->execute();
  
  while(my $row = $sth->fetchrow_hashref) {
  
    my $key = $row->{i_id};
  
    my %data = ();
   
    $data{itemName} = $row->{i_external_id};
    $data{itemStatus} = $item_status_label{$row->{iia_type}};
  
    $importActionList{$key} = \%data; 
  }
  
  return [ $q->psgi_header('text/html'), [ &print_welcome() ]];
}
# All done!

sub print_welcome {
  my $psgi_out = '';

    my $msg = (
        defined( $in{message} )
        ? '<div style="color:#ff0000;font-weight:bold">'
          . $in{message}
          . "</div>"
        : "" );

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <title>CDE Item Import Detail</title>
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

    </script>
  </head>
  <body>
    <div class="title">Item Import Detail</div>
    ${msg} 
   <br />
   <table id="viewTable" class="tablesorter" border="1" cellspacing="2" cellpadding="2" align="left">
     <thead>
     <tr>
       <th width="100">Item</th>
       <th width="100">Status</th>
     </tr>
     </thead>
     <tbody>
END_HERE

    foreach my $key (sort { $importActionList{$a}{itemName} cmp $importActionList{$b}{itemName} }
                     keys %importActionList) {

      my $data = $importActionList{$key};

      $psgi_out .= <<END_HERE;
      <tr>
        <td>$data->{itemName}</td>
        <td>$data->{itemStatus}</td>
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
