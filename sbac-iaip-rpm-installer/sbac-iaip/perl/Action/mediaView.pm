package Action::mediaView;

use Cwd;
use URI;
use URI::Escape;
use ItemConstants;
use ItemAsset;

sub run {

  our $q = shift;
  our $dbh = shift;

  our %in = map { $_ => $q->param($_) } $q->param;
  our $user = Session::getUser($q->env, $dbh);

  our $asset = new ItemAsset( $in{itemBankId}, $in{itemName}, $in{version}, $in{imageId} );
  
  my($assetHtml, $documentReadyFunction, $cssIncludes,  $jsIncludes);

  $cssIncludes = <<CSS_INCLUDES;
      <link href="${orcaUrl}style/text.css" rel="stylesheet" type="text/css">
CSS_INCLUDES
  
  if ($asset->{ext} eq "swf") {
      $assetHtml = <<END_HERE;
  <OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" width="550" height="400">
    <PARAM NAME="movie" VALUE="$asset->{url}">
    <PARAM NAME="FlashVars" VALUE="">
    <PARAM NAME="quality" VALUE="high">
    <EMBED SRC="$asset->{url}" FlashVars="" quality="high" WIDTH="550" HEIGHT="400" TYPE="application-x-shockwave-flash" />
  </OBJECT>
END_HERE
  } else {
      my $playerId = "orca_media_$in{itemName}_$asset->{title}";
      $cssIncludes .= <<CSS_INCLUDES;
  <link href="${commonUrl}style/jplayer/jplayer.blue.monday.css" rel="stylesheet" type="text/css">
CSS_INCLUDES
      $documentReadyFunction .= getMediaReadyFunction( $playerId, $asset->{ext}, $asset->{url}, $asset->{path} );
      $jsIncludes = <<JS_INCLUDES;
  <script type="text/javascript" src="${commonUrl}js/jquery-1.4.2.min.js"></script>
      <script type="text/javascript" src="${commonUrl}js/jquery.jplayer.min.js"></script>
      <script type="text/javascript">
      <!--
  
        \$(document).ready(function() {
          ${documentReadyFunction}
        });
  
      //-->
      </script>
JS_INCLUDES
      $assetHtml = getMediaHtml($playerId, $asset->{ext}, $asset->{title}, $asset->{path});
  }
  
  my $psgi_out = <<END_HERE;
  <!DOCTYPE html>
  <html>
    <head>
      <title>Display Media</title>
      <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
      ${cssIncludes}
      ${jsIncludes}
    </head>
    <body>
     <div class="title">$asset->{title}</div>
     ${assetHtml}
    </body>
  </html>
END_HERE

  return [ $q->psgi_header('text/html'), [ $psgi_out ]];
}
1;

