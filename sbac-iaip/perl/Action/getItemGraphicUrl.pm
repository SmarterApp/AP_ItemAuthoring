package Action::getItemGraphicUrl;

use Cwd;
use URI;
use URI::Escape;
use ItemConstants;
use Session;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $debug = 1;
  
  our $thisUrl = "${orcaUrl}cgi-bin/getItemGraphicUrl.pl";
  
  our $sth;
  our $sql;
  
  our $banks = defined($user->{banks}) ? $user->{banks} : &getItemBanks( $dbh, $user->{id} );
  
  $sql =
    "SELECT i_external_id, ib_id, i_version FROM item WHERE i_id=$in{itemId}";
  $sth = $dbh->prepare($sql);
  $sth->execute();
  my $row = $sth->fetchrow_hashref;
  
  our $itemBankId     = $row->{ib_id};
  our $itemExternalId = $row->{i_external_id};
  our $version        = $row->{i_version};
  
  return [ $q->psgi_header(
              -type          => 'text/html',
              -pragma        => 'nocache',
              -cache_control => 'no-cache, must-revalidate'),
            [ &print_preview( ) ]];
  
}
### ALL DONE! ###

sub print_preview {
  my $psgi_out = '';

    my $params      = shift;
    my $itemBankName   = $banks->{ $itemBankId }{name};
    my $valueField   = $in{valueField};

    $psgi_out .= <<END_HERE;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="x-ua-compatible" content="IE=9" />
    <title>Find Item Graphic</title>
    <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
    <script type="text/javascript">
    <!--
      function alertProps(obj) {
        var output = '';
	for (var prop in obj) {
	  output += prop + ' = ' + obj[prop] + '\\n';
        }
	alert(output);
      }

      function copyImageTag (url)
      {
	 window.opener.document.editForm.${valueField}.value = url; 
	 window.opener.document.editForm.submit();
	 window.close(); 
      }	 
      
    //-->
    </script>
  </head>
  <body>
    <div class="title">Graphics for this Item</div>
    <br />
END_HERE

    my %graphic_ext = map {$_ => 1} @graphic_extensions;

    foreach my $asset ( sort { $b->{date} <=> $a->{date} } 
                        grep { exists $graphic_ext{ $_->{ext} } }
        &getItemAssets( $itemBankId, $itemExternalId, $version ) )
    {

        my $assetHtml = <<HTML;
	<tr>
	  <td valign="top"><input type="button" value="Select" onClick="copyImageTag('$asset->{url}'); return true;"></td>
	  <td>
HTML

        if($asset->{ext} eq 'svg') {
	  $assetHtml .= <<HTML;
	  <object data="$asset->{url}" type="image/svg+xml" wmode="transparent" width="$asset->{width}" height="$asset->{height}"></object>
HTML
        } else {
          $assetHtml .= <<HTML;
	  <img style="border:0px;" src="$asset->{url}" />
HTML
        }

        $assetHtml .= '</td></tr>';

        $psgi_out .= <<END_HERE;
	<table border="1" cellpadding="2" cellspacing="2">
        <tr><th colspan="2"><b>$asset->{title}</b></th></tr>
	    ${assetHtml}
	</table><br />
END_HERE
    }

    $psgi_out .= "</body></html>\n";
  return $psgi_out;
}
1;
